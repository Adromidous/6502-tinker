# 6502-Project

ALOHA and Welcome!

This is another one of my projects (more on the hardware side of things). I used this project to help me understand computers at a lower level and apply the concepts of hardware design and low level programming I learned in class.

While highly inspired by Ben Eater's 6502, there are a few things I added on my own (more to come...) 6502 that I thought would be good enough to post on Github.

Some of the features include:  
  1. 6502 initialization code (Registers, I/O, RAM, ROM)
  2. Added memory mapped RAM, ROM and VIA (Versatile Interface Adapter)
  3. Added Versatile Interface Adapter for I/O and other peripheral devices such as push buttons. 
  4. Developed priority interrupts so the 6502 doesn't have to poll each device when an interrupt is signaled and each device has a priority when handling the interrupts (Device 0 with the highest and device 7 with the lowest).
  5. Developed a Bootloader so that I can seek through my ROM before running the program or just run the program itself.


Below I've included some pictures of the screens that the user can select through. For now there is only a **SEEK ROM** and **RUN** option but I'm currently developing other options that the user can pick from.

**1. HOME SCREEN**  
![image](https://github.com/Adromidous/6502-tinker/assets/110305385/7fd317b9-172a-4dd0-984f-db994eb34b7b)

**2. OPTIONS TO CHOOSE FROM - SCAN ROM AND RUN**
![image](https://github.com/Adromidous/6502-tinker/assets/110305385/29656aa7-e5cb-4a94-8c76-8a2cc71ac621)
![image](https://github.com/Adromidous/6502-tinker/assets/110305385/cd998d17-df46-4795-b426-a8c3a71f7dd6)

**3. UPON CLICKING THE 'RUN' OPTION, I STORED A HELLO WORLD PROGRAM**
![image](https://github.com/Adromidous/6502-tinker/assets/110305385/ce32e361-ecb2-491d-8a53-b462fbcc8e23)

**4. UPON CLICKING THE 'SCAN ROM' OPTION, THE USER CAN SEEK THROUGH ALL THE ADDRESS SPACES**
![image](https://github.com/Adromidous/6502-tinker/assets/110305385/e578a39e-9c0c-46d4-8ee3-88ae0a7be452)
![image](https://github.com/Adromidous/6502-tinker/assets/110305385/49392b88-786d-4a21-b9b3-848c66361f56)
![image](https://github.com/Adromidous/6502-tinker/assets/110305385/146d8837-1be6-475d-ba26-0a707dfac0cc)
![image](https://github.com/Adromidous/6502-tinker/assets/110305385/2e55052a-b383-462d-b46f-58f69164afc6)


There are many more things I'm looking forward to develop with the 6502 so stay tuned!

Enjoy your day and take care!!!
