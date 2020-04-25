# Space Invaders Video Game

The Space Invaders Video Game is the final project of [The University of British Columbia](https://www.edx.org/school/ubcx)'s
[How to Code: Simple Data online course](http://www.edx.org/course/how-to-code-simple-data) offered on [edx.org](https://www.edx.org/).
There are notable additions that distinguish my game from others. I have listed
them to benefit others who may utilize my code to expand upon their own:

* space invaders move at different speeds
* space invaders move in different directions
* the conclusion of the game is met with the _GAME OVER_ screen

## Getting started

1. Download DrRacket (**reminder: adjust specifications of your system**) and install on your local machine: [Download Racket](https://download.racket-lang.org/)

2. Download the zip file from this repo: [Download zip](https://github.com/nicoleiocana/space-invaders/archive/master.zip)

    ![download zip file](https://imgur.com/n3hhOQi.png)

3. Unzip the file. Inside the `space-invaders` folder, double-click on the _space-invaders.rkt_ file.

4. Run the program; the button is located in the top right corner:

    ![run](https://imgur.com/M9erUsS.png)

5. After all tests pass, type this in the interactions section to play the game:

    `(main G0)`

## Difficulty Modifications

If you wish to reduce the rate of space invaders that spawn on screen, go to line 265 and increase the number 3 in:

`(< (random INVADE-RATE) 3)`

**note: anything larger than 7 is insane. Good luck!**

If you wish to reduce the speed at which the space invaders travel, go to line 266 and decrease the number 4 in:

`(+ (random 4) 1)`

**note: replacing this entire section with a positive number produces a constant rate in either direction.**

## Domain Analysis

![domain analysis](https://imgur.com/L3EM3Dj.png)

## Screen Capture

![gameplay](https://i.imgur.com/6GtAejl.gif)
