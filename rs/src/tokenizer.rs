use std::char;

use self::Tok::*;

#[derive(Debug,PartialEq)]
pub enum Tok {
    Bra, Ket, Quot,
    Num(i64),
    Sym(String),
    Str(String)
}

#[derive(Debug,Clone,Copy,PartialEq)]
pub enum State {
    Ok, BadEscape, UnfinishedStr
}

impl State {
    pub fn describe(&self) -> &'static str {
        match *self {
            State::Ok => "Ok",
            State::BadEscape =>
                "Invalid escape code in string.",
            State::UnfinishedStr =>
                "Expected an ending quote, but the token stream finished \
                 before one was received"
        }
    }
}

pub struct Tokenizer<'a> {
    state : State,
    input : &'a str,
    pos   : usize
}

macro_rules! peek {
    ($tokenizer : expr, $c : ident; $($($p : pat),+ => $e : expr),* ) => {{
        while let Some($c) = $tokenizer.peek_char() {
            match $c { $($($p)|+ => $e),* }
        }
    }}
}

macro_rules! next {
    ($tokenizer : expr, $c : ident; $($($p : pat),+ => $e : expr),* ) => {{
        while let Some($c) = $tokenizer.next_char() {
            match $c { $($($p)|+ => $e),* }
        }
    }}
}

impl<'a> Tokenizer<'a> {

    pub fn new(input : &'a str) -> Self {
        Tokenizer { state: State::Ok, input: input, pos: 0 }
    }

    pub fn state(&self) -> State { self.state }

    fn peek_char(&self) -> Option<char> {
        self.input[self.pos..].chars().next()
    }

    fn next_char(&mut self) -> Option<char> {
        self.peek_char()
            .map(|c| { self.pos += c.len_utf8(); c })
    }

    fn following<F>(&self, f : F) -> bool
        where F : FnOnce(char) -> bool
    {
        self.peek_char().map_or(false, f)
    }

    fn eat_line(&mut self) {
        peek!(self, c;
              '\n' => break,
              _    => { self.next_char(); });
    }

    fn next_digits(&mut self, init : char, radix : u32) -> Option<i64> {
        init.to_digit(radix)
            .map(|init| {
                let mut acc = init as i64;

                peek!(self, c;
                      '_' => { self.next_char(); },
                      _   => if let Some(d) = c.to_digit(radix) {
                          self.next_char();
                          acc = acc * (radix as i64) + (d as i64);
                      } else {
                          break
                      });
                acc
            })
    }

    fn slice_str(&mut self) -> Option<Tok> {
        macro_rules! u { ($c:expr) => { Some($c as char) } }

        let mut acc = String::new();
        next!(self, c;
              '"'  => { return Some(Str(acc)) },
              '\\' => {
                  let chm =
                      self.next_char()
                      .and_then(|escape : char| -> Option<char> {
                          match escape {
                              '0'  => u!(0x0000),
                              'a'  => u!(0x0007),
                              'b'  => u!(0x0008),
                              't'  => u!(0x0009),
                              'n'  => u!(0x000a),
                              'v'  => u!(0x000b),
                              'f'  => u!(0x000c),
                              'r'  => u!(0x000d),
                              '"'  => u!(0x0022),
                              '\'' => u!(0x0027),
                              '\\' => u!(0x005c),
                              'u'  => {
                                  self.next_char()
                                      .and_then(|init|
                                                self.next_digits(init, 16))
                                      .and_then(|code|
                                                char::from_u32(code as u32))
                              }
                              _    => Some(escape)
                          }
                      });

                  if let Some(ch) = chm {acc.push(ch); }
                  else {
                      self.state = State::BadEscape;
                      return None;
                  };
              },
              _ => acc.push(c));

        self.state = State::UnfinishedStr;
        None
    }

    fn slice_num(&mut self, init : char, sign : i64) -> Option<Tok> {
        self.next_digits(init, 10)
            .map(|val| Num(sign * val))
    }

    fn slice_sym(&mut self, init : char) -> Option<Tok> {
        let mut name = String::new();
        name.push(init);

        peek!(self, c;
              ' ', '\t', '\n', ',', ';',
              '(', ')', '\'', '&', '"' => break,
              _ => {
                  self.next_char();
                  name.push(c);
              });

        Some(Sym(name))
    }
}

impl<'a> Iterator for Tokenizer<'a> {
    type Item = Tok;

    fn next(&mut self) -> Option<Tok> {
        if self.state != State::Ok { return None }

        peek!(self, c;
              ' ', ',', '\t', '\n', '\r' => { self.next_char(); },
              ';' => { self.eat_line(); },
              _   => break);

        self.next_char()
            .and_then(|c| {
                match c {
                    '('  => Some(Bra),
                    ')'  => Some(Ket),
                    '\'' => Some(Quot),
                    '&'  => Some(Sym("&".to_string())),
                    '"'  => self.slice_str(),
                    '0'...'9'
                         => self.slice_num(c, 1),
                    '+' | '-' if self.following(|c| c.is_digit(10))
                         => {
                             let init = self.next_char().unwrap();
                             self.slice_num(init, if c == '+' { 1 } else { -1 })
                         }
                    _    => self.slice_sym(c)
                }
            })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    macro_rules! tok_test {
        ($input : expr, $($t:expr),* ) => {{
            let t = Tokenizer::new($input);
            assert_eq!(t.collect::<Vec<Tok>>(),
                       vec![$($t),*]);
        }}
    }

    macro_rules! tsym {($s : expr) => { Tok::Sym($s.to_string()) }}
    macro_rules! tstr {($s : expr) => { Tok::Str($s.to_string()) }}

    #[test]
    fn punctuation() {
        tok_test!("(", Tok::Bra);
        tok_test!(")", Tok::Ket);
        tok_test!("'", Tok::Quot);
        tok_test!("&", tsym!("&"));
    }

    #[test]
    fn numbers() {
        tok_test!("1", Tok::Num(1));
        tok_test!("+1", Tok::Num(1));
        tok_test!("-23", Tok::Num(-23));
        tok_test!("1_000", Tok::Num(1000));
    }

    #[test]
    fn symbols() {
        tok_test!("foo", tsym!("foo"));
        tok_test!("+", tsym!("+"));
        tok_test!("my-var-name", tsym!("my-var-name"));
        tok_test!("var-1", tsym!("var-1"));

        tok_test!("hello wor;; comment\nld",
                  tsym!("hello"), tsym!("wor"), tsym!("ld"));

        tok_test!("foo(bar)baz",
                  tsym!("foo"),
                  Tok::Bra, tsym!("bar"), Tok::Ket,
                  tsym!("baz"));

        tok_test!("foo'bar",
                  tsym!("foo"), Tok::Quot, tsym!("bar"));

        tok_test!("foo&bar",
                  tsym!("foo"), tsym!("&"), tsym!("bar"));
    }

    #[test]
    fn strings() {
        tok_test!("\"\"", tstr!(""));
        tok_test!("\"foo\"", tstr!("foo"));
        tok_test!("\"foo\\nbar\"", tstr!("foo\nbar"));
        tok_test!("\"\\u000a\"", tstr!("\n"));

        tok_test!("\"foo\\\"bar\"", tstr!("foo\"bar"));

        tok_test!("\"foo\" \"bar\"",
                  tstr!("foo"), tstr!("bar"));
    }

    #[test]
    fn sequences() {
        tok_test!("(foo 1)",
                  Tok::Bra, tsym!("foo"),
                  Tok::Num(1), Tok::Ket);

        tok_test!("(1 foo)",
                  Tok::Bra, Tok::Num(1),
                  tsym!("foo"), Tok::Ket);

        tok_test!("foo bar", tsym!("foo"), tsym!("bar"));
        tok_test!("foo\nbar", tsym!("foo"), tsym!("bar"));
        tok_test!("foo,bar", tsym!("foo"), tsym!("bar"));
    }

    #[test]
    fn comments() {
        tok_test!("foo ;; comment\n bar",
                  tsym!("foo"), tsym!("bar"));
    }
}
