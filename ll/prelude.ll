;; Constants
(def nil  '())
(def true 't)
(def false nil)

;; Definitions
(def defmacro
     (macro
      (name & body)
      (cons 'def (cons name (cons (cons 'macro body) nil)))))

(defmacro defn (name & body)
  (cons 'def (cons name (cons (cons 'fn body) nil))))

(defmacro let (ass body)
  (list (list 'fn (list (head ass))
              body)
        (head (tail ass))))

(defmacro do (& body)
  (list (cons 'fn (cons nil body))))

;; List
(defn list (& vals) vals)

(defn foldr (f e xs)
  (if (= nil xs)
    e
    (f (head xs)
       (foldr f e (tail xs)))))

(defn foldl (f e xs)
  (if (= nil xs)
    e
    (foldl f (f e (head xs))
           (tail xs))))

(defn map (f xs)
  (foldr (fn (x ys) (cons (f x) ys)) nil xs))

(defn filter (p xs)
  (foldr (fn (x ys) (if (p x) (cons x ys) ys)) nil xs))

(defn len (xs)
  (foldl (fn (acc _) ($add acc 1)) 0 xs))

(defn rev (xs)
  (foldl (fn (ys y) (cons y ys)) nil xs))

;; Arithmetic Operations
(defn inc (x) ($add x 1))
(defn dec (y) ($sub x 1))

(defn + (& xs) (foldr $add 0 xs))

(defn - (x & xs)
  (if (= nil xs)
    ($sub 0 x)
    (foldl $sub x xs)))

(defn * (& xs)
  (foldr $mul 1 xs))

(defn / (x y & xs)
  (foldl $div ($div x y) xs))

(defn % (x y) ($mod x y))
