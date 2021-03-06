(define (map f l)
  (if (null? l)
    '()
    (cons (f (car l)) (map f (cdr l)))))

(define (call-cc-api table-name func-name . args)
  (define (scm/lua->lua obj)
    (cond ((lua-object? obj) obj)
          (#t (scm->lua obj))))
  (let* ((t (lua-gettable (lua-get-g) (scm->lua table-name)))
        (fn (scm->lua func-name))
        (a (map scm/lua->lua args))
        (func (lua-gettable t fn))
        (ret (apply lua-call (cons func a)))
        (first-ret (lua-gettable ret (scm->lua 1))))
    first-ret))

(define (sleep s)
  (call-cc-api "os" "sleep" s) #t)

(define (display str)
  (call-cc-api "io" "write" (scm->lua str) (scm->lua "\n"))
  #t)

(define (lamp-on)
  (call-cc-api "redstone" "setOutput" "top" #t))

(define (lamp-off)
  (call-cc-api "redstone" "setOutput" "top" #f))

(define (turtle func-name . args)
  (apply call-cc-api (cons "turtle" (cons func-name args))))

(define (turtle-move dir)
  (cond ((eq? dir 'forward) (turtle "forward"))
        ((eq? dir 'back) (turtle "turnLeft") (turtle "turnLeft") (turtle "forward"))
        ((eq? dir 'left) (turtle "turnLeft") (turtle "forward"))
        ((eq? dir 'right) (turtle "turnRight") (turtle "forward"))
        ((eq? dir 'up) (turtle "up"))
        ((eq? dir 'down) (turtle "down"))))

(define (turtle-dance)
  (turtle-move 'up)
  (turtle "turnRight")
  (turtle "turnLeft")
  (turtle "turnLeft")
  (turtle "turnRight")
  (turtle-move 'up)
  (turtle-move 'forward)
  (turtle-move 'back)
  (turtle-move 'forward)
  (turtle-move 'back)
  (turtle-move 'down)
  (turtle-move 'down))

(define (goal?)
  (let ((ret (turtle "compareDown")))
    (lua->scm ret)))

(define (block-forward?)
  (let ((ret (turtle "detect")))
    (lua->scm ret)))

(define (block-left?)
  (turtle "turnLeft")
  (let ((ret (turtle "detect")))
    (turtle "turnRight")
    (lua->scm ret)))

(define (block-right?)
  (turtle "turnRight")
  (let ((ret (turtle "detect")))
    (turtle "turnLeft")
    (lua->scm ret)))

(define (block-up?)
  (let ((ret (turtle "detectUp")))
    (lua->scm ret)))

(define (block-down?)
  (let ((ret (turtle "detectDown")))
    (lua->scm ret)))

(define (maze)
  (let ittr ()
    (cond ((goal?) (turtle-dance) (turtle-move 'back))
          ((not (block-right?)) (turtle-move 'right) (ittr))
          ((not (block-forward?)) (turtle-move 'forward) (ittr))
          ((not (block-left?)) (turtle-move 'left) (ittr))
          (#t (turtle-move 'back) (ittr)))))

(define (tree-grow?)
  (turtle "select" 1)
  (let ((ret (turtle "compare")))
    (lua->scm ret)))

(define (store-woods)
  (turtle "turnLeft")
  (turtle "turnLeft")
  (let ittr ((n 2))
    (cond
      ((<= n 16) (turtle "select" n) (turtle "drop") (ittr (+ n 1)))
      (#t #t)))
  (turtle "turnLeft")
  (turtle "turnLeft"))

(define (get-sapling)
  (turtle "select" 2)
  (turtle "suckDown" 1))

(define (put-sapling)
  (turtle "select" 2)
  (turtle "place"))

(define (cut-woods)
  (turtle "select" 1)
  (let ittr ()
    (cond
      ((block-forward?) (turtle "dig") (turtle "digUp") (turtle-move 'up) (ittr))
      (#t #t)))
  (let ittr ()
    (cond
      ((not (block-down?)) (turtle-move 'down) (ittr))
      (#t #t))))

(define (wood-cutter)
  (let ittr ()
    (cond ((tree-grow?) (cut-woods) (store-woods) (get-sapling) (put-sapling) (ittr))
          (#t (sleep 1) (ittr)))))

#t
