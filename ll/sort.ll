(require "prelude.ll")

(defn insert (xs x)
  (cond
    ((= xs nil) (list x))

    ((< x (head xs))
     (cons x xs))

    ('else
     (cons (head xs)
           (insert (tail xs) x)))))

(defn sort (xs)
  (foldl insert nil xs))

(defn range (from to)
  (cond
    ((= from to) nil)
    ((< from to) (cons from (range (inc from) to)))
    ('else       (cons from (range (dec from) to)))))

(puts (sort (range 1 11)))
