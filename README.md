# ABB RobotStudio - Basic control of the YuMi (IRB 14000) collaborative robot

## Requirements:

**Software:**
```bash
ABB RobotStudio 2021.1.2 (64-bit)
```

**RobotWare:**
```bash
Version 6.12.0
```

| Software/Package      | Link                                                                                  |
| --------------------- | ------------------------------------------------------------------------------------- |
| ABB RobotStudio       | https://new.abb.com/products/robotics/robotstudio/downloads                           |

## Project Description:

The project demonstrates a few examples in ABB RobotStudio to control the collaborative robot YuMi (IRB 140000). The main goal of the project is the design of conveyor belt control, cooperation with multiple arms and simple manipulation of the object using an smart gripper (ABB).

Main challenges of project implementation:
- object manipulation using a smart gripper (ABB)
- cooperation of both robotic arms synchronously
- conveyor belt control
- clean rapid program using functions, structures, etc.

The project was created to improve the [VRM (Programming for Robots and Manipulators)](https://github.com/rparak/Programming-for-robots-and-manipulators-VRM) university course.

The project was realized at the Institute of Automation and Computer Science, Brno University of Technology, Faculty of Mechanical Engineering (NETME Centre - Cybernetics and Robotics Division).

**Unpacking a station (/Final/Solution_YuMi.rspag):**
1. On the File tab, click Open and then browse to the folder and select the Pack&Go file, the Unpack & Work wizard opens.
2. In the Welcome to the Unpack & Work Wizard page, click Next.
3. In the Select package page, click Browse and then select the Pack & Go file to unpack and the Target folder. Click Next.
4. In the Library handling page select the target library. Two options are available, Load files from local PC or Load files from Pack & Go. Click the option to select the location for loading the required files, and click Next.
5. In the Virtual Controller page, select the RobotWare version and then click Locations to access the RobotWare Add-in and Media pool folders. Optionally, select the check box to automatically restore backup. Click Next.
6. In the Ready to unpack page, review the information and then click Finish.

<p align="center">
  <img src="https://github.com/rparak/ABB-RobotStudio-YUMI/blob/main/images/1_1.png" width="800" height="500">
  <img src="https://github.com/rparak/ABB-RobotStudio-YUMI/blob/main/images/1_2.PNG" width="800" height="450">
</p>

## Project Hierarchy:

**Repositary [/ABB-RobotStudio-YUMI/]:**

```bash
[ Main Program (.rspag)                ] /Final/
[ Example of the resulting application ] /Exe_file/
[ Rapid codes (.mod) - Right/Left Arm  ] /Rapid/
[ Scene without a robot                ] /Project_Materials/.sat/
[ Scene with a robot (Inventor)        ] /Project_Materials/Pack_and_Go/
```

## Application:

<p align="center">
  <img src="https://github.com/rparak/ABB-RobotStudio-YUMI/blob/main/images/2_1.png" width="800" height="450">
  <img src="https://github.com/rparak/ABB-RobotStudio-YUMI/blob/main/images/2_2.png" width="800" height="450">
  <img src="https://github.com/rparak/ABB-RobotStudio-YUMI/blob/main/images/2_3.png" width="800" height="450">
  <img src="https://github.com/rparak/ABB-RobotStudio-YUMI/blob/main/images/2_4.png" width="800" height="450">
  <img src="https://github.com/rparak/ABB-RobotStudio-YUMI/blob/main/images/2_5.png" width="800" height="450">
  <img src="https://github.com/rparak/ABB-RobotStudio-YUMI/blob/main/images/2_6.png" width="800" height="450">
  <img src="https://github.com/rparak/ABB-RobotStudio-YUMI/blob/main/images/2_7.png" width="800" height="450">
</p>

## Result:

Youtube: https://www.youtube.com/watch?v=NlBHzPffA0o&t=3s

## Contact Info:
Roman.Parak@outlook.com

## Citation (BibTex)
```bash
@misc{RomanParak_ABB_RS,
  author = {Roman Parak},
  title = {A few examples of robot control in the ABB RobotStudio simulation tool},
  year = {2019-2021},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/rparak/ABB-RobotStudio-YUMI/}}
}
```

## License
[MIT](https://choosealicense.com/licenses/mit/)
