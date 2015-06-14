;;;;;;;;;;; Constants ;;;;;;;;;;

(def nil  '())
(def true 't)
(def false nil)

;;;;;;;;;;; Core Syntax ;;;;;;;;;;

(def defmacro
     (macro
      (name & body)
      (cons 'def (cons name (cons (cons 'macro body) nil)))))

(defmacro defn (name & body)
  (cons 'def (cons name (cons (cons 'fn body) nil))))

(defmacro let (ass body)
  (list (list 'fn (list (fst ass))
              body)
        (snd ass)))

(defmacro do (& body)
  (list (list* 'fn '() body)))

(defmacro cond (& pairs)
  (let (emit-pair
        (fn (p rest)
            (list 'if (fst p)
                  (snd p)
                  rest)))
    (foldr emit-pair 'nil pairs)))

;;;;;;;;;; Functions ;;;;;;;;;;

(defn flip (f) (fn (y x) (f x y)))

(defn comp (f g) (fn (& xs) (f (apply g xs))))

(defn partial (f & xs)
  (fn (& ys) (apply f (concat xs ys))))

;;;;;;;;;; List ;;;;;;;;;;

(defn list (& vals) vals)

(defn list* (& vals)
  (foldr1 cons vals))

(defn concat (xs ys)
  (foldr cons ys xs))

(defn fst (xs) (head xs))
(defn snd (xs) (head (tail xs)))

(defn foldr (f e xs)
  (if ($eq nil xs) e
    (f (head xs)
       (foldr f e (tail xs)))))

(defn foldl (f e xs)
  (if ($eq nil xs) e
    (foldl f (f e (head xs))
           (tail xs))))

(defn foldr1 (f xs)
  (if ($eq nil (tail xs))
    (head xs)
    (f (head xs)
       (foldr1 f (tail xs)))))

(defn map (f xs)
  (foldr (fn (x ys) (cons (f x) ys)) nil xs))

(defn filter (p xs)
  (foldr (fn (x ys) (if (p x) (cons x ys) ys)) nil xs))

(defn len (xs)
  (foldl (fn (acc _) ($add acc 1)) 0 xs))

(defn rev (xs)
  (foldl (fn (ys y) (cons y ys)) nil xs))

(defn interleave (i xs)
  (do (defn interleave* (xs)
        (if ($eq nil xs) nil
          (list* i (head xs)
                 (interleave* (tail xs)))))

      (if ($eq nil xs) nil
        (cons (head xs)
              (interleave* (tail xs))))))

(defn take (n xs)
  (if (or ($eq n 0) ($lt n 0) ($eq nil xs)) nil
    (cons (head xs)
          (take (dec n)
                (tail xs)))))

(defn drop (n xs)
  (if (or ($eq n 0) ($lt n 0) ($eq nil xs)) xs
    (drop (dec n) (tail xs))))

(defn pairwise (xs)
  (if (or ($eq nil xs)
          ($eq nil (tail xs)))
    nil
    (cons (take 2 xs)
          (pairwise (tail xs)))))

(defn all? (p xs)
  (foldl (fn (b x) (and b (p x))) true xs))

(defn any? (p xs)
  (foldl (fn (b x) (or b (p x))) false xs))

;;;;;;;;;; Arithmetic Operations ;;;;;;;;;;

(defn inc (x) ($add x 1))
(defn dec (x) ($sub x 1))

(defn + (& xs) (foldr $add 0 xs))

(defn - (x & xs)
  (if ($eq nil xs)
    ($sub 0 x)
    (foldl $sub x xs)))

(defn * (& xs)
  (foldr $mul 1 xs))

(defn / (x y & xs)
  (foldl $div ($div x y) xs))

(defn % (x y) ($mod x y))

;;;;;;;;;; Macro Helpers ;;;;;;;;;;

(def gensym
     (do (def counter 1)
         (fn (name)
             (set! counter (inc counter))
             (sym (str name counter)))))

;;;;;;;;;; Boolean Operations ;;;;;;;;;;

(defn not (b)
  (if b false true))

(defmacro and (& vals)
  (if ($eq nil vals) 'true
    (let ($and
          (fn (b c)
              (let (v (gensym 'and))
                (list 'let (list v b)
                      (list 'if v c v)))))
      (foldr1 $and vals))))

(defmacro or (& vals)
  (let ($or
        (fn (b c)
            (let (v (gensym 'or))
              (list 'let (list v b)
                    (list 'if v v c)))))
    (foldr $or 'false vals)))

;;;;;;;;;; Comparison Operations ;;;;;;;;;;

(defn comp-op (op rands)
  (all? (fn (p) (op (fst p) (snd p)))
        (pairwise rands)))

(defn = (x y & xs)
  (comp-op $eq (list* x y xs)))

(defn < (x y & xs)
  (comp-op $lt (list* x y xs)))

(defn > (x y & xs)
  (comp-op (flip $lt) (list* x y xs)))

(defn <= (x y & xs)
  (comp-op (fn (x y) (or ($lt x y)
                         ($eq x y)))
           (list* x y xs)))

(defn >= (x y & xs)
  (comp-op (fn (x y) (or ($lt y x)
                         ($eq x y)))
           (list* x y xs)))

;;;;;;;;;; Printing ;;;;;;;;;;

(defn puts (& xs)
  (print (apply str (interleave " " xs))))
