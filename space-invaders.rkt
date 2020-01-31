;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-abbr-reader.ss" "lang")((modname space-invaders) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
(require 2htdp/universe)
(require 2htdp/image)

;; Space Invaders


;; Constants:

(define WIDTH  300)
(define HEIGHT 500)

(define INVADER-X-SPEED 1.5)  ;speeds (not velocities) in pixels per tick
(define INVADER-Y-SPEED 1.5)
(define TANK-SPEED 2)
(define MISSILE-SPEED 10)

(define HIT-RANGE 10)

(define INVADE-RATE 100)

(define BACKGROUND (empty-scene WIDTH HEIGHT))

(define INVADER
  (overlay/xy (ellipse 10 15 "outline" "blue")              ;cockpit cover
              -5 6
              (ellipse 20 10 "solid"   "blue")))            ;saucer

(define TANK
  (overlay/xy (overlay (ellipse 28 8 "solid" "black")       ;tread center
                       (ellipse 30 10 "solid" "green"))     ;tread outline
              5 -14
              (above (rectangle 5 10 "solid" "black")       ;gun
                     (rectangle 20 10 "solid" "black"))))   ;main body

(define TANK-HEIGHT/2 (/ (image-height TANK) 2))

(define MISSILE (ellipse 5 15 "solid" "red"))



;; Data Definitions:

(define-struct game (invaders missiles tank))
;; Game is (make-game  (listof Invader) (listof Missile) Tank)
;; interp. the current state of a space invaders game
;;         with the current invaders, missiles and tank position

;; Game constants defined below Missile data definition

#;
(define (fn-for-game g)
  (... (fn-for-loi  (game-invaders g))
       (fn-for-lom  (game-missiles g))
       (fn-for-tank (game-tank g))))

(define-struct tank (x dir))
;; Tank is (make-tank Number Integer[-1, 1])
;; interp. the tank location is x, HEIGHT - TANK-HEIGHT/2 in screen coordinates
;;         the tank moves TANK-SPEED pixels per clock tick left if dir -1, right if dir 1

(define T0 (make-tank (/ WIDTH 2) 1))   ;center going right
(define T1 (make-tank 50 1))            ;going right
(define T2 (make-tank 50 -1))           ;going left

#;
(define (fn-for-tank t)
  (... (tank-x t)     ; Number[0, WIDTH]
       (tank-dir t))) ; Integer[-1,1]

;; Template Rules Used:
;; - compound: 2 fields

(define-struct invader (x y dx))
;; Invader is (make-invader Number Number Number)
;; interp. the invader is at (x, y) in screen coordinates
;;         the invader along x by dx pixels per clock tick

(define I1 (make-invader 150 100 12))           ;not landed, moving right
(define I2 (make-invader 150 HEIGHT -10))       ;exactly landed, moving left
(define I3 (make-invader 150 (+ HEIGHT 10) 10)) ;> landed, moving right

#;
(define (fn-for-invader invader)
  (... (invader-x invader)     ; Number[0, WIDTH]
       (invader-y invader)     ; Number[0, HEIGHT]
       (invader-dx invader)))  ; Number

;; Template Rules Used:
;; - compound: 3 fields

;; ListOfInvader is one of:
;; - empty
;; - (cons Invader ListOfInvader)
;; interp. a list of invaders

(define LOI0 empty)
(define LOI1 (list I1))
(define LOI2 (list I1 I2))
(define LOI3 (list I1 I2 I3))

#;
(define (fn-for-loi loi)
  (cond [(empty? loi) (...)]
        [else 
         (... (fn-for-invader (first loi))
              (fn-for-loi (rest loi)))]))

;; Template Rules Used:
;; - one of: 2 cases
;; - atomic distinct: empty
;; - compound: (cons Invader ListofInvader)
;; - reference: (first loi) is Invader
;; - self-reference: (rest loi) is ListOfInvader

(define-struct missile (x y))
;; Missile is (make-missile Number Number)
;; interp. the missile's location is x y in screen coordinates

(define M1 (make-missile 150 300))                               ;not hit U1
(define M2 (make-missile (invader-x I1) (+ (invader-y I1) 10)))  ;exactly hit U1
(define M3 (make-missile (invader-x I1) (+ (invader-y I1)  5)))  ;> hit U1
(define M4 (make-missile 150 100))

#;
(define (fn-for-missile m)
  (... (missile-x m) (missile-y m)))

;; ListOfMissile is one of:
;; - empty
;; - (cons Missile ListOfMissile)
;; interp. a list of missiles

(define LOM0 empty)
(define LOM1 (list M1))
(define LOM2 (list M1 M2))

#;
(define (fn-for-lom lom)
  (cond [(empty? lom) (...)]
        [else 
         (... (fn-for-missile (first lom))
              (fn-for-lom (rest lom)))]))

;; Template Rules Used:
;; - one of: 2 cases
;; - atomic distinct: empty
;; - compound: (cons Missile ListofMissile)
;; - reference: (first lom) is Missile
;; - self-reference: (rest lom) is ListOfMissile

(define G0 (make-game empty empty T0))
(define G1 (make-game empty empty T1))
(define G2 (make-game (list I1) (list M1) T1))
(define G3 (make-game (list I1 I2) (list M1 M2) T1))

;; =================
;; Functions:

;; Game -> Game
;; start the world with (main G0)
;; 
(define (main g)
  (big-bang g                                 ; Game
    (on-tick   next-game)                     ; Game -> Game         
    (to-draw   render-game)                   ; Game -> Image
    (on-key    handle-keys)                   ; Game KeyEvent -> Game
    (stop-when game-over? gos)))              ; Game -> Boolean

;; Game -> Game
;; produce the next game state

;(define (next-game g) (make-game empty empty T0)) ;stub

;<template from Game>

(define (next-game g)
  (make-game (create-invaders (next-invaders (destroy-invaders (game-invaders g) (game-missiles g))))
             (next-missiles (destroy-missiles (game-missiles g) (game-invaders g)))
             (next-tank (game-tank g))))

;; ListofInvader -> ListofInvader
;; produce filtered and ticked list of invaders
(check-expect (next-invaders LOI0) LOI0)
(check-expect (next-invaders LOI1) (cons (make-invader 168 118 12) empty))
(check-expect (next-invaders LOI2) (cons (make-invader 168 118 12)
                                         (cons (make-invader 135 515 -10) empty)))
                                        
;<template as composite function>

(define (next-invaders loi)
  (onscreen-invaders (tick-invaders loi)))

;; ListofInvader -> ListofInvader
;; produce list of ticked invaders
(check-expect (tick-invaders LOI0) LOI0)
(check-expect (tick-invaders LOI1) (cons (make-invader (+ 150 (* 12 INVADER-X-SPEED)) (+ 100 (* 12 INVADER-Y-SPEED)) 12) empty))
(check-expect (tick-invaders LOI2) (cons (make-invader (+ 150 (* 12 INVADER-X-SPEED)) (+ 100 (* 12 INVADER-Y-SPEED)) 12)
                                         (cons (make-invader (+ 150 (* -10 INVADER-X-SPEED)) (+ HEIGHT (* 10 INVADER-Y-SPEED)) -10) empty)))

;<template from ListofInvader>

(define (tick-invaders loi)
  (cond [(empty? loi) empty]
        [else
         (cons (tick-invader (first loi))
               (tick-invaders (rest loi)))]))

;; Invader -> Invader
;; produce a new invader that is advanced:
;;    product of INVADER-X-SPEED & dx pixel(s) per clock tick in the appropriate x direction: negative value means left, positive right
;;    product of INVADER-Y-SPEED & the absolute value of dx pixel(s) per clock tick downward
(check-expect (tick-invader I1) (make-invader (+ 150 (* 12 INVADER-X-SPEED)) (+ 100 (* 12 INVADER-Y-SPEED)) 12))
(check-expect (tick-invader I2) (make-invader (+ 150 (* -10 INVADER-X-SPEED)) (+ HEIGHT (* 10 INVADER-Y-SPEED)) -10))

;<template from Invader>

(define (tick-invader i)
  (make-invader (+ (invader-x i) (* (invader-dx i) INVADER-X-SPEED)) (+ (invader-y i) (* (abs (invader-dx i)) INVADER-Y-SPEED)) (invader-dx i)))

;; ListofInvader -> ListofInvader
;; produce a list containing only those invaders in loi that are within the left & right boundaries
(check-expect (onscreen-invaders LOI0) LOI0)
(check-expect (onscreen-invaders LOI1) LOI1)

(check-expect (onscreen-invaders (cons (make-invader WIDTH 10 20) empty)) (cons (make-invader WIDTH 10 20) empty))
(check-expect (onscreen-invaders (cons (make-invader WIDTH 10 -20) empty)) (cons (make-invader WIDTH 10 -20) empty))

(check-expect (onscreen-invaders (cons (make-invader (+ WIDTH 20) 10 20) empty)) (cons (make-invader WIDTH 10 -20) empty))
(check-expect (onscreen-invaders (cons (make-invader (- 0 30) 45 -30) empty)) (cons (make-invader 0 45 30) empty))

;<template from ListofInvader>

(define (onscreen-invaders loi)
  (cond [(empty? loi) empty]
        [else
         (cons (invader-onscreen (first loi))
               (onscreen-invaders (rest loi)))]))

;; Invaders -> Invaders
;; produce invaders inside the left or right boundaries if necessary
(check-expect (invader-onscreen (make-invader 0 10 15)) (make-invader 0 10 15))
(check-expect (invader-onscreen (make-invader 0 10 -15)) (make-invader 0 10 -15))

(check-expect (invader-onscreen (make-invader WIDTH 10 20)) (make-invader WIDTH 10 20))
(check-expect (invader-onscreen (make-invader WIDTH 10 -20)) (make-invader WIDTH 10 -20))

(check-expect (invader-onscreen (make-invader (+ WIDTH 20) 10 20)) (make-invader WIDTH 10 -20))
(check-expect (invader-onscreen (make-invader (- 0 30) 45 -30)) (make-invader 0 45 30))

;<template from Invaders>

(define (invader-onscreen i)
  (cond [(> (invader-x i) WIDTH) (make-invader WIDTH (invader-y i) (- (invader-dx i)))]
        [(< (invader-x i) 0) (make-invader 0 (invader-y i) (- (invader-dx i)))]
        [else
         (make-invader (invader-x i) (invader-y i) (invader-dx i))]))

;; ListofInvader -> ListofInvader
;; randomly adds invaders to the list depending on the INVADER-RATE. Invaders randomly generate at height 0 and x coordinate
;; within the WIDTH of the screen. Their dx is randomly assigned along with left/right direction.

;(define (create-invaders loi) loi) ;stub

(define (create-invaders loi)
  (if (< (random INVADE-RATE) 3)
      (cons (make-invader (random WIDTH) 0 (* (if (< (random 4) 2) 1 -1) (+ (random 4) 1))) loi)
      loi))

;; ListofInvader ListofMissile -> ListofInvader
;; produces a list of invaders that have not been hit by a missile from the list of missiles.
;; Define "hit by a missile" such that the x, y position of the missile is (x +- HIT-RANGE, y +- HIT-RANGE) of the invader
(check-expect (destroy-invaders LOI0 LOM0) LOI0)
(check-expect (destroy-invaders LOI1 LOM0) LOI1)
(check-expect (destroy-invaders (cons (make-invader 100 200 10) empty)
                                (cons (make-missile 150 300) empty))
              (cons (make-invader 100 200 10) empty))

(check-expect (destroy-invaders (cons (make-invader 150 310 -10) empty)
                                (cons (make-missile 150 300) empty))
              empty)
(check-expect (destroy-invaders (cons (make-invader 150 290 -10) empty)
                                (cons (make-missile 150 300) empty))
              empty)

(check-expect (destroy-invaders (cons (make-invader 110 200 5) empty)
                                (cons (make-missile 100 200) empty))
              empty)
(check-expect (destroy-invaders (cons (make-invader 90 200 5) empty)
                                (cons (make-missile 100 200) empty))
              empty)
(check-expect (destroy-invaders (cons (make-invader 100 200 10) (cons (make-invader 150 300 -5) empty))
                                (cons (make-missile 150 300) empty))
              (cons (make-invader 100 200 10) empty))

;(define (destroy-invaders loi lom) loi) ;stub

;<template from ListofInvader>

(define (destroy-invaders loi lom)
  (cond [(empty? loi) empty]
        [(empty? lom) loi]
        [else
         (if (destroy-invader? (first loi) lom)
             (destroy-invaders (rest loi) lom)
             (cons (first loi) (destroy-invaders (rest loi) lom)))]))

;; Invader ListofMissile -> Boolean
;; produce true if one invader has been hit by the missile
(check-expect (destroy-invader? (make-invader 100 200 5) (cons (make-missile 0 0) empty))
              false)
(check-expect (destroy-invader? (make-invader 100 200 -5) (cons (make-missile 100 200) empty))
              true)

;(define (destroy-invader? i lom) true) ;stub

;<template from Invader with extra atomic paramter>

(define (destroy-invader? i lom)
  (cond [(empty? lom) false]
        [else
         (if (and (<= (- (invader-x i) HIT-RANGE) (missile-x (first lom)) (+ (invader-x i) HIT-RANGE))
                  (<= (- (invader-y i) HIT-RANGE) (missile-y (first lom)) (+ (invader-y i) HIT-RANGE)))
             true
             (destroy-invader? i (rest lom)))]))
         

;; ListOfMissile -> ListOfMissile
;; produce filtered and ticked list of missiles
(check-expect (next-missiles LOM0) LOM0)
(check-expect (next-missiles (cons (make-missile 75 100) empty)) (cons (make-missile 75 90) empty))
(check-expect (next-missiles (cons (make-missile 75 100) (cons (make-missile  175 200) empty)))
              (cons (make-missile 75 90) (cons (make-missile 175 190) empty)))


;<template as function composition>

(define (next-missiles lom)
  (onscreen-missiles (tick-missiles lom)))


;; ListOfMissile -> ListOfMissile
;; produce list of ticked missiles
(check-expect (tick-missiles LOM0) LOM0)
(check-expect (tick-missiles (cons (make-missile 75 100) empty)) (cons (make-missile 75 (- 100 MISSILE-SPEED)) empty))
(check-expect (tick-missiles (cons (make-missile 75 100) (cons (make-missile  175 200) empty)))
              (cons (make-missile 75 (- 100 MISSILE-SPEED)) (cons (make-missile 175 (- 200 MISSILE-SPEED)) empty)))


;<template from ListOfMissile>

(define (tick-missiles lom)
  (cond [(empty? lom) empty]
        [else 
         (cons (tick-missile (first lom))
               (tick-missiles (rest lom)))]))


;; Missile -> Missile
;; produce a new missile that is advanced upward by MISSILE-SPEED pixel(s) per clock tick on the BACKGROUND
(check-expect (tick-missile M1) (make-missile 150 (- 300 MISSILE-SPEED)))

;<template from Missile>

(define (tick-missile m)
  (make-missile (missile-x m) (- (missile-y m) MISSILE-SPEED)))


;; ListOfMissile -> ListOfMissile
;; produce a list containing only those missiles in lom that are onscreen. Onscreen means where the y coordinate is greater than or equal to 0.
(check-expect (onscreen-missiles LOM0) LOM0)
(check-expect (onscreen-missiles LOM1) LOM1)

(check-expect (onscreen-missiles (cons (make-missile 0 (/ HEIGHT 2)) empty)) (cons (make-missile 0 (/ HEIGHT 2)) empty))
(check-expect (onscreen-missiles (cons (make-missile WIDTH (/ HEIGHT 2)) empty)) (cons (make-missile WIDTH (/ HEIGHT 2)) empty))

(check-expect (onscreen-missiles (cons (make-missile 0 0) empty)) (cons (make-missile 0 0) empty))

(check-expect (onscreen-missiles (cons (make-missile 50 (- 0 2)) empty)) empty)
(check-expect (onscreen-missiles (cons (make-missile 150 300) (cons (make-missile 50 (- 0 5)) empty)))
              (cons (make-missile 150 300) empty))


;<template from ListOfMissile>

(define (onscreen-missiles lom)
  (cond [(empty? lom) empty]
        [else
         (if (missile-onscreen? (first lom))
             (cons (first lom) (onscreen-missiles (rest lom)))
             (onscreen-missiles (rest lom)))]))


;; Missile -> Boolean
;; produce true if missile has not fallen off the upper boundary of the BACKGROUND
(check-expect (missile-onscreen? (make-missile 2 -1)) false)
(check-expect (missile-onscreen? (make-missile 2  0)) true)
(check-expect (missile-onscreen? (make-missile 2  1)) true)

;<template from Missile>

(define (missile-onscreen? m)  
  (<= 0 (missile-y m)))

;; ListofMissile ListofInvader -> ListofMissile
;; produces a list of missiles that have not been intersected with an invader from the list of invaders.
;; Define "intersected with an invader" such that the x, y position of the missile is (x +- HIT-RANGE, y +- HIT-RANGE) of the invader
(check-expect (destroy-missiles LOM0 LOI0) LOM0)
(check-expect (destroy-missiles LOM0 LOI1) LOM0)
(check-expect (destroy-missiles (cons (make-missile 150 300) empty)
                                (cons (make-invader 100 200 10) empty))
              (cons (make-missile 150 300) empty))

(check-expect (destroy-missiles (cons (make-missile 150 300) empty)
                                (cons (make-invader 150 310 -10) empty))
              empty)
(check-expect (destroy-missiles (cons (make-missile 150 300) empty)
                                (cons (make-invader 150 290 -10) empty))
              empty)

(check-expect (destroy-missiles (cons (make-missile 100 200) empty)
                                (cons (make-invader 110 200 5) empty))
              empty)
(check-expect (destroy-missiles (cons (make-missile 100 200) empty)
                                (cons (make-invader 90 200 5) empty))
              empty)

;(define (destroy-missiles lom loi) lom) ;stub

(define (destroy-missiles lom loi)
  (cond [(empty? lom) empty]
        [(empty? loi) lom]
        [else
         (if (destroy-missile? (first lom) loi)
             (destroy-missiles (rest lom) loi)
             (cons (first lom) (destroy-missiles (rest lom) loi)))]))

;; Missile ListofInvader -> Boolean
;; produce true if one missile has intersected with an invader
(check-expect (destroy-missile? (make-missile 0 0) (cons (make-invader 100 200 5) empty))
              false)
(check-expect (destroy-missile? (make-missile 100 200) (cons (make-invader 100 200 -5) empty))
              true)

;(define (destroy-missile? m loi) true) ;stub

(define (destroy-missile? m loi)
  (cond [(empty? loi) false]
        [else
         (if (and (<= (- (missile-x m) HIT-RANGE) (invader-x (first loi)) (+ (missile-x m) HIT-RANGE))
                  (<= (- (missile-y m) HIT-RANGE) (invader-y (first loi)) (+ (missile-y m) HIT-RANGE)))
             true
             (destroy-missile? m (rest loi)))]))

;; Tank -> Tank
;; advance tank by TANK-SPEED pixel(s) per clock tick in its appropriate direction
(check-expect (next-tank T0) (make-tank (+ (/ WIDTH 2) TANK-SPEED) 1))
 
;<template as composite function>
                                        
(define (next-tank t)
  (tank-onscreen (tick-tank t)))

;; Tank -> Tank
;; advance tank x by TANK-SPEED pixel(s) per clock tick:
;;    left if dir -1
;;    right if dir 1
(check-expect (tick-tank T0) (make-tank (+ (/ WIDTH 2) TANK-SPEED) 1))
(check-expect (tick-tank T2) (make-tank (- 50 TANK-SPEED) -1))

;<template from Tank>

(define (tick-tank t)
  (if (= (tank-dir t) 1)
      (make-tank (+ (tank-x t) TANK-SPEED) 1)
      (make-tank (- (tank-x t) TANK-SPEED) -1)))

;; Tank -> Tank
;; advance tank depending on when it gets to an edge, change its direction and move off by 1
(check-expect (tank-onscreen (make-tank 20 1)) (make-tank 20 1))
(check-expect (tank-onscreen (make-tank 20 -1)) (make-tank 20 -1))

(check-expect (tank-onscreen (make-tank WIDTH 1)) (make-tank WIDTH 1))
(check-expect (tank-onscreen (make-tank 0 -1)) (make-tank 0 -1))

(check-expect (tank-onscreen (make-tank (+ WIDTH TANK-SPEED) 1)) (make-tank WIDTH -1))
(check-expect (tank-onscreen (make-tank (- 0 TANK-SPEED) -1)) (make-tank 0 1))

;<template from Tank>

(define (tank-onscreen t)
  (cond [(> (tank-x t) WIDTH) (make-tank WIDTH -1)]
        [(< (tank-x t) 0) (make-tank 0 1)]
        [else
         (make-tank (tank-x t) (tank-dir t))]))

;; Game -> Image
;; render the image of the current world state of the game

;(define (render-game g) BACKGROUND) ;stub

(define (render-game g)
  (render-invaders (game-invaders g)
                   (render-missiles (game-missiles g)
                                    (render-tank (game-tank g)))))

;; ListofInvader Image -> Image
;; render the invaders onto the BACKGROUND
(check-expect (render-invaders LOI0 BACKGROUND) BACKGROUND)
(check-expect (render-invaders LOI1 BACKGROUND)
              (place-image INVADER
                           150
                           100
                           BACKGROUND))

;(define (render-invaders loi img) img) ;stub

;<template from ListofInvader w/ extra atomic parameter>

(define (render-invaders loi img)
  (cond [(empty? loi) img]
        [else
         (place-image INVADER
                      (invader-x (first loi))
                      (invader-y (first loi))
                      (render-invaders (rest loi) img))]))

;; ListofMissile Image -> Image
;; render the missiles onto the BACKGROUND
(check-expect (render-missiles LOM0 BACKGROUND) BACKGROUND)
(check-expect (render-missiles LOM1 BACKGROUND)
              (place-image MISSILE
                           150
                           300
                           BACKGROUND))
(check-expect (render-missiles (cons M1 (cons M4 empty)) BACKGROUND)
              (place-image MISSILE
                           150
                           300
                           (place-image MISSILE
                                        150
                                        100
                                        BACKGROUND)))


;(define (render-missiles lom img) img) ;stub

;<template from ListofMissile w/ extra atomic parameter>

(define (render-missiles lom img)
  (cond [(empty? lom) img]
        [else
         (place-image MISSILE
                      (missile-x (first lom))
                      (missile-y (first lom))
                      (render-missiles (rest lom) img))]))


;; Tank -> Image
;; render the tank onto the BACKGROUND
(check-expect (render-tank (make-tank 50 1))
              (place-image TANK
                           50
                           (- HEIGHT TANK-HEIGHT/2)
                           BACKGROUND))

;(define (render-tank t) BACKGROUND) ;stub

;<template from Tank>

(define (render-tank t)
  (place-image TANK (tank-x t) (- HEIGHT TANK-HEIGHT/2) BACKGROUND))


;; Game KeyEvent -> Game
;; if key pressed is:
;;    left arrow - tank heads in left direction
;;    right arrow - tank heads in right direction
;;    spacebar - new missile shooting upward is created at the tank's x, y position
(check-expect (handle-keys G0 "down") G0)
(check-expect (handle-keys G0 " ")
              (make-game (game-invaders G0)
                         (cons (make-missile (tank-x (game-tank G0)) (- HEIGHT TANK-HEIGHT/2)) (game-missiles G0))
                         (game-tank G0)))
(check-expect (handle-keys G1 "left")
              (make-game (game-invaders G1)
                         (game-missiles G1)
                         (make-tank (tank-x (game-tank G1)) -1)))
(check-expect (handle-keys G2 "right")
              (make-game (game-invaders G2)
                         (game-missiles G2)
                         (make-tank (tank-x (game-tank G2)) 1)))

;(define (handle-keys g ke) G0) ;stub

;; Templated according to KeyEvent large enumeration.
(define (handle-keys g ke)
  (cond [(key=? ke "left") (make-game (game-invaders g) (game-missiles g) (handle-left (game-tank g)))]
        [(key=? ke "right") (make-game (game-invaders g) (game-missiles g) (handle-right (game-tank g)))]
        [(key=? ke " ") (make-game (game-invaders g) (handle-spacebar (game-missiles g) (game-tank g)) (game-tank g))]
        [else g]))

;; Tank -> Tank
;; produces a tank heading in the left direction when the left arrow is pressed
(check-expect (handle-left (make-tank 50 1)) (make-tank 50 -1))
(check-expect (handle-left (make-tank 100 -1)) (make-tank 100 -1))

;(define (handle-left t) (make-tank 0 -1)) ;stub

(define (handle-left t)
  (make-tank (tank-x t) -1))

;; Tank -> Tank
;; produces a tank heading in the right direction when the right arrow is pressed
(check-expect (handle-right (make-tank 50 1)) (make-tank 50 1))
(check-expect (handle-right (make-tank 100 -1)) (make-tank 100 1))

;(define (handle-right t) (make-tank 0 1)) ;stub

(define (handle-right t)
  (make-tank (tank-x t) 1))

;; ListofMissile Tank -> ListofMissile
;; adds a missile to the list shooting upward from the x position of the tank when the space bar is pressed
(check-expect (handle-spacebar LOM0 T0) (cons (make-missile (/ WIDTH 2) (- HEIGHT TANK-HEIGHT/2)) LOM0))
(check-expect (handle-spacebar LOM1 T1) (cons (make-missile 50 (- HEIGHT TANK-HEIGHT/2)) LOM1))

;(define (handle-spacebar lom t) LOM0) ;stub

(define (handle-spacebar lom t)
  (cons (make-missile (tank-x t) (- HEIGHT TANK-HEIGHT/2)) lom))

;; Game -> Boolean
;; ends the game once an invader reaches the bottom of the BACKGROUND
(check-expect (game-over? G0) false)

(define (game-over? g)
  (invaders-height? (game-invaders g)))

;; ListofInvader -> Boolean
;; ends the game once an invader reaches the bottom of the BACKGROUND

(define (invaders-height? loi)
  (cond [(empty? loi) false]
        [else
         (if (>= (invader-y (first loi)) HEIGHT)
             true
             (invaders-height? (rest loi)))]))

;; Game -> Image
;; produces the game over screen

; (define (gos g) BACKGROUND) ;stub

(define (gos g)
  (place-image (text "GAME OVER" 50 "red") (/ WIDTH 2) (/ HEIGHT 2) (render-game g)))