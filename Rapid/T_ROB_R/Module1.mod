MODULE Module1
    ! ## =========================================================================== ## 
    ! MIT License
    ! Copyright (c) 2021 Roman Parak
    ! Permission is hereby granted, free of charge, to any person obtaining a copy
    ! of this software and associated documentation files (the "Software"), to deal
    ! in the Software without restriction, including without limitation the rights
    ! to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    ! copies of the Software, and to permit persons to whom the Software is
    ! furnished to do so, subject to the following conditions:
    ! The above copyright notice and this permission notice shall be included in all
    ! copies or substantial portions of the Software.
    ! THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    ! IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    ! FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    ! AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    ! LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    ! OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    ! SOFTWARE.
    ! ## =========================================================================== ## 
    ! Author   : Roman Parak
    ! Email    : Roman.Parak@outlook.com
    ! Github   : https://github.com/rparak
    ! File Name: T_ROB_R/Module1.mod
    ! ## =========================================================================== ##
    
    ! Robot Parameters Structure
    RECORD robot_param
        speeddata speed;
        zonedata zone;
        num obj_offset;
        num wait_sgT;
    ENDRECORD
    ! Robot Control Structure
    RECORD robot_ctrl_str
        num actual_state;
        syncident syncT;
        robot_param r_param; 
    ENDRECORD
    
    ! Call Main Structure
    VAR robot_ctrl_str r_str;
    
    ! Main waypoints (targets) for robot control
    CONST robtarget Target_Home_R:=[[298.859230972,-285.123,108.077570746],[-0.000000043,1,0.000002488,-0.00000597],[-1,1,0,0],[107.880618475,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_Conv_R:=[[475.065,-285.123,37.011],[0.000000043,1,0.000002488,-0.00000597],[-1,0,2,0],[107.880618475,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_Sync_R:=[[310.064993699,-43.010993226,174.876983856],[0.707106812,-0.707106751,0.000002462,0.000005981],[-1,1,1,0],[107.880618995,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    ! PERS Variables -> Communication between multiple Tasks (T_ROB_L, T_ROB_R)
    ! Use synchronization move (simple animation) -> CASE 5
    PERS bool sync_anim_move;
    ! Initialization Tasks for synchronization
    PERS tasks Task_list{2} := [ ["T_ROB_L"], ["T_ROB_R"] ];
    
    ! ################################## ABB YUMI (RIGHT ARM) - Main Cycle ################################## !
    PROC main()
        TEST r_str.actual_state
            CASE 0:
                ! ******************** INITIALIZATION STATE ******************** !
                ! Initialize the parameters
                INIT_PARAM;
                ! Restore the environment
                RESET_ENV;
                ! Move -> Home position
                MoveJ Target_Home_R,r_str.r_param.speed,fine,Servo\WObj:=wobj0; 
                ! Change state -> {Wait signal from the Conveyor}
                r_str.actual_state := 1;
            CASE 1:
                ! ******************** Conveyor State ******************** !
                ! Wait for the digital input from the simulation logic
                ! -> until the command from the conveyor sensor is issued (the TAB. is in position)
                ! << Equivalent to WaitDO DI_CONV_SENS, 1; >>
                ! Check the condition of the conveyor (In position or Not)
                IF DI_CONV_SENS = 1 THEN
                    ! Reset digital output (Conveyor stopped)
                    SetDO DO_CONV_MOVE, 0;
                    ! Change state -> {P&P (Conveyor -> Sync.)}
                    r_str.actual_state := 2;
                ENDIF
            CASE 2:
                ! ******************** Pick&Place OBJ. CONV. STATE ******************** !
                ! Call function for the P&P trajectory (from the position of the conveyor to the sync. position | use fingers on the gripper (SG -> Smart gripper))
                PP_CONV_SYNC;
                ! Change state -> {Wait for the signal}
                r_str.actual_state := 3;
            CASE 3:
                ! ******************** WAIT STATE (SYNC. Move) ******************** !
                ! Pulse signal for Robot Arm (L) -> motion command (The robot R is in position)
                PulseDO DO_INPOS_ROB_R;
                
                IF sync_anim_move = FALSE THEN
                    ! Change state -> {Without animation -> Wait for the signal (Place Obj.}
                    r_str.actual_state := 4;
                ELSEIF sync_anim_move = TRUE THEN                
                   ! Change state -> {Synchronize the Tasks -> Start animation}
                    r_str.actual_state := 5;
                    ! Wait for tasks to sync.
                    WaitSyncTask r_str.syncT, Task_list;
                    ! Turn On -> Synchronization
                    SyncMoveOn r_str.syncT, Task_list;
                ENDIF
            CASE 4:
                 ! ******************** WAIT STATE (Back to Home - Init) ******************** !
                ! Wait for the digital input from the T_ROB_L
                ! -> until the command is issued from the arm (the Robot is in position)
                WaitDO DO_INPOS_ROB_L, 1;
                PulseDO DO_OPEN_GR;
                
               IF sync_anim_move = TRUE THEN
                    ! Turn Off -> Synchronization
                    SyncMoveOff r_str.syncT;
                ENDIF
                
                ! Move to the Position -> (with offset: without the object)
                MoveL Offs(Target_Sync_R, 0, -100, 0),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
                
                ! Change state -> {Back to Home}
                r_str.actual_state := 10;
            CASE 5:
                ! ******************** SYNC. MOVE STATE ******************** !
                SYNC_MOVE_FCE 1, r_str.r_param.speed, r_str.r_param.zone, 100, 50;
                ! Change state -> {Wait for the signal (Back to Home - Init}
                r_str.actual_state := 4;
            CASE 10:
                ! ******************** Back to Home STATE ******************** !
                ! Move -> Home position
                MoveJ Target_Home_R,r_str.r_param.speed,fine,Servo\WObj:=wobj0; 
                ! Change state -> {empty}
                r_str.actual_state := 100;
            CASE 100:
                ! ******************** EMPTY STATE ******************** !
        ENDTEST
        
    ENDPROC
    
    ! ################################## P&P FUNCTION (CONV -> SYNC) ################################## !
    PROC PP_CONV_SYNC()
        ! ====== Pick Trajectory ====== !
        MoveL Offs(Target_Conv_R, 0, 0, 100),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
        MoveL Offs(Target_Conv_R, 0, 0, 0),r_str.r_param.speed,fine,Servo\WObj:=wobj0;
        ! Signal -> Move the position of the fingers (SyncePose): Gripp the object
        WaitTime r_str.r_param.wait_sgT;
        PulseDO DO_CLOSE_GR;
        ! Signal -> Attach the object: The location of the object is on the conveyor.
        PulseDO DO_ATTACH_OBJ_R;
        WaitTime r_str.r_param.wait_sgT;
        MoveL Offs(Target_Conv_R, 0, 0, 100),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
        ! ====== Place Trajectory ====== !
        MoveJ Offs(Target_Sync_R, 0, -100, 0),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
        MoveL Offs(Target_Sync_R, 0, 0, 0),r_str.r_param.speed,fine,Servo\WObj:=wobj0;
        ! Signal -> Detach the object: The location of the object is on the conveyor.
        PulseDO DO_DETACH_OBJ_R;
        WaitTime r_str.r_param.wait_sgT;
    ENDPROC
    ! ################################## SYNC. MOVE FUNCTION ################################## !
    PROC SYNC_MOVE_FCE(num sync_id, speeddata speed, zonedata zone, num offs_param_y, num offs_param_z)
        ! ========================================================== !
        ! Description: Simple function for synchronizing the movement of multiple arms.
        ! The function creates a simple animation of the movement in a rectangle.
        !
        ! IN:
        ! [1] sync_id: numerical value of synchronization movements
        ! [2] speed: speed of individual movements
        ! [3] zone: zone of individual movements
        ! [4] offs_param_y: rectangle parameter of Y (offset y-axis)
        ! [5] offs_param_z: rectangle parameter of Z (offset z-axis)
        ! ========================================================== !
        
        ! Synchronization movement
        ! (1) Move -> Right
        MoveL Offs(Target_Sync_R, 0, (-1)*offs_param_y, 0),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (2) Move -> Up
        MoveL Offs(Target_Sync_R, 0, (-1)*offs_param_y, offs_param_z),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (3) Move -> Left
        MoveL Offs(Target_Sync_R, 0, offs_param_y, offs_param_z),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (4) Move -> Down
        MoveL Offs(Target_Sync_R, 0, offs_param_y, (-1)*offs_param_z),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (5) Move -> Right
        MoveL Offs(Target_Sync_R, 0, (-1)*offs_param_y, (-1)*offs_param_z),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (6) Move -> Up (Middle)
        MoveL Offs(Target_Sync_R, 0, (-1)*offs_param_y, 0),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (7) Move -> Home position
        MoveL Offs(Target_Sync_R, 0, 0, 0),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
    ENDPROC
    ! ################################## INIT PARAMETERS ################################## !
    PROC INIT_PARAM()
        ! Intitialization parameters of the robot
        ! Speed
        r_str.r_param.speed := [200, 200, 200, 200];
        ! Zone
        r_str.r_param.zone  := z50;
        ! Object offset
        r_str.r_param.obj_offset := 100;
        ! Wait time (Smart Gripper) -> [seconds]
        r_str.r_param.wait_sgT := 0.25;
    ENDPROC
    ! ################################## RESET ENVIRONMENT ################################## !
    PROC RESET_ENV()
        ! Reset DO (Digital Output)
        ! Detacher {Environment}
        PulseDO DO_RESET_ENV; 
        ! Detacher {Control Object}
        PulseDO DO_DETACH_OBJ_R;
        ! Digital output (Conveyor stopped)
        SetDO DO_CONV_MOVE, 0;
        ! Smart Gripper -> Release (Home Position)
        PulseDO DO_OPEN_GR;
    ENDPROC
    ! ################################## TEST TARGETS ################################## !
    PROC Path_20()
        MoveL Target_Home_R,v1000,z100,Servo\WObj:=wobj0;
        MoveL Target_Conv_R,v1000,z100,Servo\WObj:=wobj0;
        MoveL Target_Sync_R,v1000,z100,Servo\WObj:=wobj0;
    ENDPROC
ENDMODULE