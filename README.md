# 6502-Project

ALOHA and Welcome!

This is another one of my projects (more on the hardware side of things). I used this project to help me understand computers at a lower level and apply the concepts of hardware design and low level programming I learned in class.

While highly inspired by Ben Eater's 6502, there are a few things I added on my own (more to come...) 6502 that I thought would be good enough to post on Github.

Some of the features include:  
  1. 6502 initialization code (Registers, I/O, RAM, ROM)
  2. Added memory mapped RAM, ROM and VIA (Versatile Interface Adapter)
  3. Added Versatile Interface Adapter for I/O with user and other peripheral devices such as push buttons. 
  4. Developed priority interrupts so the 6502 doesn't have to poll each device when an interrupt is signaled and each device has a priority when handling the interrupts (Device 0 with the highest and device 7 with the lowest).
  5. Developed a Bootloader so that I can seek through my ROM before running the program or just run the program itself.

There are many more things I'm looking forward to develop with the 6502 so stay tuned!

Enjoy your day and take care!!!
