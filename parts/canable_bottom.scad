/*
 -------------------------------------
 * OpenSCAD design CANable
 * Author: Loek Lankhorst
 * Date: May 29 2025
 * License: MIT
 * Copyright (c) 2025 Loek Lankhorst
 -------------------------------------
*/

include <BOSL2/std.scad>
include <BOSL2/screws.scad>

usb_c_dim = [9, 8.4, 3.3];
usb_c_offset = 1.0;
usb_c_rounding_edges = [RIGHT+TOP, LEFT+TOP, RIGHT+BOT, LEFT+BOT];

screw_terminal_cube_dim = [15.3, 6.92, 4.3];
screw_terminal_prism_dim1 = [15.3, 6.92];
screw_terminal_prism_dim2 = [15.3, 4.8];
screw_terminal_prism_h = 4.5;

db9_solder_body_dim = [19.28, 9, 12.51];
db9_slot_dim = [30.84, 1.12, 12.51];

board_dim = [15.3, 40.11, 1.69];


usb_wall_thickness = 2;
bottom_thickness=2;

// Configure this for the distance between DB9 and the PCB
board_db9_spacing = 15;

function db9_board_translate(spacing) = [0, -spacing - db9_solder_body_dim.y - board_dim.y/2, 0];

module board(){
    attachable(anchor=TOP, orient=UP, spin=0){
        recolor("#1F1F1F")
            cube(board_dim, anchor=BOT){
            
                // USB-C connector
                back(usb_c_offset)
                    position(TOP+BACK)
                        recolor("silver")
                            cuboid(usb_c_dim, rounding=1, 
                                            edges=usb_c_rounding_edges,
                                            anchor=BOT+BACK, $fn=100);
                
                // Screw terminal
                position(TOP+FRONT)
                    recolor("green")
                        cuboid(screw_terminal_cube_dim, anchor=BOT+FRONT){
                            position(TOP)
                                prismoid(size1=screw_terminal_prism_dim1, 
                                        size2=screw_terminal_prism_dim2, 
                                        h=screw_terminal_prism_h);
                        }
        }
        children();
    }
}

// Module: DB9 connector
// Synopsis: Connector to connect between CANable and CAN bus
// The body is attachable from the bottom
// Named anchors:
// - to_lever: connection to the lever module
module db9(){
    attachable(orient=UP, spin=0, anchor=BOT){
        color("gray")
            back(21.5)
                left(9)
                    down(10.5)
                        xrot(90)
                            import("DB9-MALE.stl", convexity=3);
        children();
    }
}

module housing_db9_lock(){
    cuboid([10, 1.5+db9_slot_dim.y, bottom_thickness],anchor=BOT+BACK){
                        position(TOP+FRONT)cuboid([10, 1.5, 1], anchor=BOT+FRONT);
                    }
}

module bottom(){
    bottom_height = board_dim.z + usb_c_dim.z + bottom_thickness;
    bottom_length = usb_wall_thickness+board_dim.y+board_db9_spacing+db9_solder_body_dim.y;

    bottom_size = [board_dim.x+5, bottom_length, bottom_height];
    
    named_anchors = [
        named_anchor("to_board", [0,bottom_size.y/2-usb_wall_thickness-board_dim.y/2,bottom_thickness], UP,0),
        named_anchor("to_db9", [0,bottom_size.y/2-usb_wall_thickness-board_dim.y-board_db9_spacing-db9_solder_body_dim.y,bottom_thickness], UP,0)
    ];

    rounding_edges = [BOT+RIGHT, BOT+LEFT, BACK+RIGHT, BACK+LEFT];
    rounding_db9_edges = [BOT+RIGHT, BOT+LEFT, BACK+RIGHT, BACK+LEFT];

    attachable(orient=UP, anchor=BOT, spin=0, anchors=named_anchors){
        diff(remove="rm"){
            cuboid(size=bottom_size, anchor=BOT, rounding=2, edges=rounding_edges, $fn=100){
                
                // Lock for DB9
                position(FRONT+BOT)
                    housing_db9_lock();

                 // Fitting for DB9
                position(FRONT+BOT)
                    cuboid(size=[db9_slot_dim.x, db9_solder_body_dim.y, db9_slot_dim.z+bottom_thickness],
                           edges=rounding_db9_edges, rounding=2, anchor=BOT+FRONT, $fn=100){
                        attach(BACK)
                            back(1)xcopies(25)
                                tag("rm")
                                    cylinder(d=3.5, h=100, anchor=CENTER);
                    }

                // Hole for USB-C
                tag("rm")
                    position(BACK+BOT)
                        fwd(usb_wall_thickness)
                            up(bottom_thickness)
                                cuboid(size=[board_dim.x, board_dim.y, board_dim.y+10], anchor=BOT+BACK);
                
                // Hole for board
                tag("rm")
                    up(bottom_thickness)
                        position(BACK+BOT)
                            cuboid(size=[usb_c_dim.x+1, usb_c_dim.y, 100], anchor=BOT);
                
                // Hole for cables and DB9
                tag("rm")
                    up(bottom_thickness + board_dim.z)
                        fwd(board_dim.y+usb_wall_thickness)
                        position(BACK+BOT)
                            cuboid(size=[board_dim.x, board_db9_spacing + db9_solder_body_dim.y, 100], anchor=BOT+BACK);

                // Hole for DB9
                tag("rm")
                    up(bottom_thickness + board_dim.z)
                        fwd(board_dim.y+usb_wall_thickness+board_db9_spacing)
                        position(BACK+BOT)
                            cuboid(size=[db9_solder_body_dim.x, db9_solder_body_dim.y, 100], anchor=BOT+BACK);
                
                // Hole for through hole pins
                tag("rm")
                    fwd(board_dim.y+usb_wall_thickness-screw_terminal_cube_dim.y/2)
                        position(BACK+BOT)
                            cuboid(size=[board_dim.x, screw_terminal_cube_dim.y/2, 100], rounding=1, anchor=CENTER);
            }
        }
        children();
    }

}

bottom(){
    // TODO: cleanup dimensions
    xcopies(25)
        up(8)
            fwd(28)
                screw("M3", head="pan", drive="phillips",length=12,orient=BACK);
    fwd(0.5)attach("to_db9")db9();
    attach("to_board")board();
}
