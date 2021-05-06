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
    ! File Name: T_ROB_L/Module1.mod
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
    CONST robtarget Target_Home_L:=[[81.638420457,319.82257735,109.364829146],[0.000000052,1,-0.000000119,-0.000000303],[1,3,0,0],[-134.999969429,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_Obj_L:=[[196.32600017,318.340999214,-17.891001928],[0.000000052,1,-0.000000119,-0.000000303],[1,3,0,0],[-134.99997239,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_Conv_L:=[[478.310945519,315.399991807,37.108861731],[0.000000052,1,-0.000000119,-0.000000303],[1,0,-2,0],[-134.999969429,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_Sync_L:=[[308.301998612,31.891000222,175.422999954],[0.707106744,0.707106818,0.00000013,-0.000000298],[1,-1,-1,0],[-134.999973742,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    ! PERS Variables -> Communication between multiple Tasks (T_ROB_L, T_ROB_R)
    ! Use synchronization move (simple animation) -> CASE 5
    PERS bool sync_anim_move;
    ! Initialization Tasks for synchronization
    PERS tasks Task_list{2} := [ ["T_ROB_L"], ["T_ROB_R"] ];
    
    ! ################################## ABB YUMI (LEFT ARM) - Main Cycle ################################## !
    PROC main()
        TEST r_str.actual_state
            CASE 0:
                ! ******************** INITIALIZATION STATE ******************** !
                ! Initialize the parameters
                INIT_PARAM;
                ! Restore the environment
                RESET_ENV;
                ! Move -> Home position
                MoveJ Target_Home_L,r_str.r_param.speed,fine,Servo\WObj:=wobj0;
                ! Change state -> {P&P (Holder Obj. -> Conveyor)}
                r_str.actual_state := 1;    
            CASE 1:
                ! ******************** Pick&Place OBJ. HOLDER STATE ******************** !
                ! Call function for the P&P trajectory (from the position of the obj. holder to the conveyor | use fingers on the gripper (SG -> Smart gripper))
                PP_OBJ_CONV;
                ! Change state -> {Start the conveyor}
                r_str.actual_state := 2;     
            CASE 2:
                ! ******************** Start the conveyor ******************** !
                ! Digital Output -> Start the conveyor (Simulation Logic)
                SetDO DO_CONV_MOVE, 1;
                ! Move to the Sync. Position (with offset)
                MoveL Offs(Target_Sync_L, 0, r_str.r_param.obj_offset, 0),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0;
                ! Change state -> {Wait for the signal}
                r_str.actual_state := 3;
            CASE 3:
                ! ******************** WAIT STATE (Pick Obj./SYNC. Move) ******************** !
                ! Wait for the digital input from the T_ROB_R
                ! -> until the command is issued from the arm (the Robot is in position)
                WaitDO DO_INPOS_ROB_R, 1;
                ! ====== Pick Trajectory ====== !
                ! Move to the Sync. Position
                MoveL Offs(Target_Sync_L, 0, 0, 0),r_str.r_param.speed,fine,Servo\WObj:=wobj0;
                ! Signal -> Move the position of the fingers (SyncePose): Gripp the object
                WaitTime r_str.r_param.wait_sgT;
                PulseDO DO_CLOSE_GL;
                ! Signal -> Attach the object: The location of the object is on the right hand.
                PulseDO DO_ATTACH_OBJ_L;
                WaitTime r_str.r_param.wait_sgT;
                
                IF sync_anim_move = FALSE THEN
                    ! Change state -> {Without animation -> Wait for the signal (Place Obj. - Init}
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
                ! ******************** WAIT STATE (Place Obj. - Init) ******************** !
                ! Pulse signal for Robot Arm (R) -> motion command (The robot L is in position)
                PulseDO DO_INPOS_ROB_L;
                
                IF sync_anim_move = TRUE THEN
                    ! Turn Off -> Synchronization
                    SyncMoveOff r_str.syncT;
                ENDIF
                
                ! Move to the Position (with object attached)
                MoveL Offs(Target_Sync_L, 0, r_str.r_param.obj_offset, 0),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
                
                ! Change state -> {P&P (Robot ARM (R) -> Holder Obj.)}
                r_str.actual_state := 9;
            CASE 5:
                ! ******************** SYNC. MOVE STATE ******************** !
                SYNC_MOVE_FCE 1, r_str.r_param.speed, r_str.r_param.zone, 100, 50;
                ! Change state -> {Wait for the signal (Place Obj. - Init}
                r_str.actual_state := 4;
            CASE 9:
                ! ====== Place Trajectory ====== !
                MoveJ Offs(Target_Obj_L, 0, 0, r_str.r_param.obj_offset),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
                MoveL Offs(Target_Obj_L, 0, 0, 0),r_str.r_param.speed,fine,Servo\WObj:=wobj0; 
                ! Signal -> Move the position of the fingers (HomePose): Release the object
                WaitTime r_str.r_param.wait_sgT;
                PulseDO DO_OPEN_GL;
                ! Signal -> Detach the object: The location of the object is on the object holder.
                PulseDO DO_DETACH_OBJ_L;
                WaitTime r_str.r_param.wait_sgT;
                MoveL Offs(Target_Obj_L, 0, 0, r_str.r_param.obj_offset),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
                ! Change state -> {Back to Home}
                r_str.actual_state := 10;
            CASE 10:
                ! ******************** Back to Home STATE ******************** !
                ! Move -> Home position
                MoveJ Target_Home_L,r_str.r_param.speed,fine,Servo\WObj:=wobj0; 
                ! Change state -> {empty}
                r_str.actual_state := 100;
            CASE 100:
                ! ******************** EMPTY STATE ******************** !
            
        ENDTEST
    ENDPROC
    
    ! ################################## P&P FUNCTION (OBJ. HOLD. -> CONV) ################################## !
    PROC PP_OBJ_CONV()
        ! ====== Pick Trajectory ====== !
        MoveL Offs(Target_Obj_L, 0, 0, r_str.r_param.obj_offset),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
        MoveL Offs(Target_Obj_L, 0, 0, 0),r_str.r_param.speed,fine,Servo\WObj:=wobj0;
        ! Signal -> Move the position of the fingers (SyncePose): Gripp the object
        WaitTime r_str.r_param.wait_sgT;
        PulseDO DO_CLOSE_GL;
        ! Signal -> Attach the object: The location of the object is on the object holder.
        PulseDO DO_ATTACH_OBJ_L;
        WaitTime r_str.r_param.wait_sgT;
        MoveL Offs(Target_Obj_L, 0, 0, r_str.r_param.obj_offset),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
        ! ====== Place Trajectory ====== !
        MoveJ Offs(Target_Conv_L, 0, 0, r_str.r_param.obj_offset),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
        MoveL Offs(Target_Conv_L, 0, 0, 0),r_str.r_param.speed,fine,Servo\WObj:=wobj0;
        ! Signal -> Move the position of the fingers (HomePose): Release the object
        WaitTime r_str.r_param.wait_sgT;
        PulseDO DO_OPEN_GL;
        ! Signal -> Detach the object: The location of the object is on the conveyor.
        PulseDO DO_DETACH_OBJ_L;
        WaitTime r_str.r_param.wait_sgT;
        MoveL Offs(Target_Conv_L, 0, 0, r_str.r_param.obj_offset),r_str.r_param.speed,r_str.r_param.zone,Servo\WObj:=wobj0; 
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
        MoveL Offs(Target_Sync_L, 0, (-1)*offs_param_y, 0),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (2) Move -> Up
        MoveL Offs(Target_Sync_L, 0, (-1)*offs_param_y, offs_param_z),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (3) Move -> Left
        MoveL Offs(Target_Sync_L, 0, offs_param_y, offs_param_z),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (4) Move -> Down
        MoveL Offs(Target_Sync_L, 0, offs_param_y, (-1)*offs_param_z),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (5) Move -> Right
        MoveL Offs(Target_Sync_L, 0, (-1)*offs_param_y, (-1)*offs_param_z),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (6) Move -> Up (Middle)
        MoveL Offs(Target_Sync_L, 0, (-1)*offs_param_y, 0),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
        ! (7) Move -> Home position
        MoveL Offs(Target_Sync_L, 0, 0, 0),\ID:=sync_id, speed,zone,Servo\WObj:=wobj0;
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
        ! Intitialization input parameters for the synchronization move
        sync_anim_move := TRUE;
    ENDPROC
    ! ################################## RESET ENVIRONMENT ################################## !
    PROC RESET_ENV()
        ! Reset DO (Digital Output)
        ! Detacher {Environment}
        PulseDO DO_RESET_ENV; 
        ! Detacher {Control Object}
        PulseDO DO_DETACH_OBJ_L;
        ! Digital output (Conveyor stopped)
        SetDO DO_CONV_MOVE, 0;
        ! Smart Gripper -> Release (Home Position)
        PulseDO DO_OPEN_GL;
    ENDPROC
    ! ################################## TEST TARGETS ################################## !
    PROC Path_10()
        MoveJ Target_Home_L,v200,fine,Servo\WObj:=wobj0;
        MoveL Target_Obj_L,v200,fine,Servo\WObj:=wobj0;
        MoveJ Target_Conv_L,v200,fine,Servo\WObj:=wobj0;
        MoveL Target_Sync_L,v200,fine,Servo\WObj:=wobj0;
    ENDPROC
ENDMODULE
