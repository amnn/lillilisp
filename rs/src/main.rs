use tokenizer::{Tokenizer, Tok};

pub mod tokenizer;

fn main() {
    let t = Tokenizer::new(
        "+-()foo bar ;;hello\n+1 -1 1_000 \
         \"hello world\" \
         \"foo\\nbar\" \
         \"\\u0022\\\"\\\\\"");
    println!("{:?}", t.collect::<Vec<Tok>>());
}
