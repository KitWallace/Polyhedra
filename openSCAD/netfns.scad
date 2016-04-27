// functions to generate a net from a polyhron
// requires conway.scad
// queue functions 
function head(queue) = 
           len(queue) > 0
               ? queue[len(queue)-1]
               : undef; 
function enque(queue,item) = dflatten(concat(item,queue),1);         
function deque(queue) =
 // remove the last entry in the queue
    len(queue) > 1
        ? [for (i=[0:len(queue)-2]) queue[i]]
        : [];


    
variedcolors=["green","blue","red","yellow","teal",
        ,"purple","orange",
        "paleGreen","slateblue","greenyellow",    
];

compcolors= [[252,141,89],[255,255,191],[145,191,219]];
twocolors= ["red","green"];
 
 
// animation shaping
function ramp(t,dwell) =
// to shape the animation to give a dwell at begining and end
   t < dwell 
       ? 0
       : t > 1 - dwell 
         ? 1
         :  ( t-dwell) /(1 - 2 * dwell);

function updown(t,dwell) =
    let(ramp=(1 - 2 * dwell)/2)
    t < dwell ? 0 :
        t < 0.5 ?( t-dwell)/ramp :
           t < 0.5 +dwell ? 1 :
              1 - (t - ramp - 2*dwell)/ramp;
  
 
module show_directed_edge(e,r=1) {
     translate(e[0]) {
         sphere(r*1.5);
         translate((e[1]-e[0])*0.8) sphere(r);
     }
}

module show_face(s,t=thickness,edge=false) {
// render (convex) face by hulling spheres placed at the vertices
    hull()
    for (i=[0:len(s) -1])
       translate(s[i]) sphere(t/2);     
    if(edge) show_directed_edge([s[0],s[1]]);
} 

module show_faces(faces,t=thickness,edge=false,colors=["yellow"]) {
   for (i=[0:len(faces)-1]) {
      face=faces[i];
      color(colors[i%len(colors)])
      show_face(face,t=thickness,edge=edge);
   }
}
 
module p_show_faces(obj,t=thickness,colors=[yellow], edge=false) {
   pf=p_faces(obj);
   pv=p_vertices(obj);
   for (i=[0:len(pf)-1]) {
      face=as_points(pf[i],pv);
      color(colors[i%len(colors)])
      show_face(face,t=thickness,edge=edge);
   }
}      
  
function face_index_with_edge(edge,faces) =   
        [for (i=[0:len(faces)-1]) 
         let (ei=index_of(edge,ordered_face_edges(faces[i])))
         if (ei != [])
            [i,ei]
        ][0];
           
function adjacent_face_edges(i,faces,side)  = 
// return [side, adj-face, adj_side] 
      let(face=faces[i],
          ofe= ordered_face_edges(face))
      [for (j=[0:len(face)-1])
         let(ei=(j-side+len(face))%len(face),
             edge=ofe[j],
             opedge=reverse(edge),
             opface_side=face_index_with_edge(opedge,faces))
        flatten([ei,opface_side])
      ] ;

function p_create_net(obj) =
// sort to get faces in nside order and start with largest
// queue entries comprise [face,side]
     let (faces=p_faces(obj),
          points=p_vertices(obj),
          kv_faces = quicksort_kv(
               [for (i=[0:len(faces)-1])
                     [face_area(as_points(faces[i],points)),i]
               ]), 
          start = head(kv_faces)[1],
          queue= [[start,0]],  
          included = [start],
          net= []) 
     create_net(faces,points,queue,included,net);

function create_net(faces,points,queue,included,net,i=0) =
     len(queue) == 0 
          ? net
          :  let(next=head(queue),
                 root=next[0],
                 side=next[1],
                 adjacent_face_edges = adjacent_face_edges(root,faces,side),
               // structured as  [ side,face_index,face_side ]
                 new_face_edges= 
                  [for (i = [0:len(adjacent_face_edges)-1])
                   let (face_edge=adjacent_face_edges[i],
                        adjacent_face=face_edge[1])
                   if (!vcontains(adjacent_face,included)) 
                       face_edge
                   ])
//             true ? adjacent_face_edges :    
             len(new_face_edges) > 0 
                 ? let (keyed_face_edges = 
                         [ for (i=[0:len(new_face_edges)-1])
                           let(fe=new_face_edges[i])
                           [face_area(as_points(faces[[fe[1]]],points)),fe]],
                       sorted_face_edges=
                           [ for (kfe=quicksort_kv(keyed_face_edges))
                             kfe[1]
                           ],                        
                        adjacent_faces= 
                            [for (fe = sorted_face_edges) fe[1]],
                        includedx = flatten(concat(included, adjacent_faces)),
                        queuex=enque(deque(queue), 
                               [for (fe=sorted_face_edges) [[fe[1],fe[2]]]]),
                        subtree= concat([root],
                               [[for (face_edge = sorted_face_edges)
                                let (adjacent_face= face_edge[1],
                                     angle=dihedral_angle_faces(root,adjacent_face,faces,points))
                                flatten(concat(face_edge,angle))
                               ]]),
                        netx=concat(net,[subtree]))
                   create_net(faces,points,queuex,includedx,netx,i+1)
                :  create_net(faces,points,deque(queue),included,net,i+1) ;
    
function face_transform(face,m) =
     [ for (v = face) m_transform(v,m) ];

function rotate_about_edge(a,face,edge) =
     let (v1 = face[edge], v2= face[(edge+1) %len(face)])
     let (m = m_rotate_about_line(a,v1,v2))
     face_transform(face,m);
                         
function face_edge(face,side) =
    [face[side], face[(side+1) %len(face)]];

function line(edge) = edge[1]-edge[0];
   
function place_face(a,base,base_side,face,face_side=0) =
//  face is the face whose face_side is to be placed on the base_side of base at angle a
//  face is on xy plane with side 0 along x axis
//  note the face_side edge is reversed when placed on the matching base side
     let (base_normal= normal(base),
          base_edgev=face_edge(base,base_side),
          base_corner=base_edgev[0],
          face_edgev=face_edge(face,face_side), 
          mb = m_rotate_to(base_normal),
          b_face= face_transform(face,mb),  // rotate face so plane is parallel to base
          b_face_corner = face_edge(b_face,face_side)[1],
          offset = base_corner - b_face_corner,
          mc = m_translate(offset),      
          c_face= face_transform(b_face,mc), // translate so face-edge[1] coincides with base_edge[0]
          c_face_edgev= reverse(face_edge(c_face,face_side)),      
          line_face=line(c_face_edgev),
          line_base=line(base_edgev),
          angle = angle_between(line_face,line_base,base_normal),  // compute angle between edges
          md =  m_rotate_about_line(angle, base_corner, base_corner +base_normal), 
          d_face= face_transform(c_face,md),  //rotate about base_edge[0] normal to the plane of base
          e_face = rotate_about_edge(a,d_face,face_side) //rotate a degrees about this edge
          )
      shift(e_face,shift=face_side);  // rotatee the sides so the edge is side 0

// rendering  
   
module p_net_render(t,net,complete,colors,scale=20,edge=false) {
    start=net[0][0];
    faces = faces_to_origin(t,scale);    
    net_faces = dflatten(net_render(net,faces,complete,start));
    mirror([0,0,1])
        show_faces(net_faces,t=thickness,edge=edge,colors=colors);
}
 
function net_render(net,faces,complete,root,current) =
   let (tree= find(root,net))
   tree == undef 
      ? []
      :
       let(
          adjacents=tree[1],
          root_face = 
              current == undef 
              ? faces[root]
              : current)
       concat ( 
              current==undef ? [root_face] : [],              // first face 
              len(adjacents) > 0
              ? [for (adjacent = adjacents)
                 let (root_side=adjacent[0],
                      face_index=adjacent[1],
                      face_side=adjacent[2],
                      dihedral=adjacent[3],
                      angle = (180-dihedral)*complete,
                      face= faces[face_index] 
                      )
                  let (tface=place_face(angle,root_face,root_side,face,face_side))
                  concat([tface],net_render(net,faces,complete,face_index,tface))
                ]
              : []   
           ); 
            
function face_to_origin(face,scale) =
   let(
       aface= face_transform(face,m_scale([scale,scale,scale])), 
       bface = face_transform(aface, m_rotate_from(normal(aface))),
       cface=face_transform(bface,m_translate(-bface[1])),
       angle = atan2(cface[0][1],cface[0][0]),    
       dface=face_transform(cface,m_rotate([0,0,-angle]))
       )
       dface;
     
function faces_to_origin(obj,scale) =
// place face with vertex 1 at the origin, vertex 0 alomg the x axis
// and in the XY plane
    let(faces=p_faces(obj), vertices=p_vertices(obj))
    [for (i=[0:len(faces)-1])
       let(face=faces[i])
       let (points = as_points(face,vertices))
       face_to_origin(points,scale)
    ];
