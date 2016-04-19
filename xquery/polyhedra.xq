import module namespace poly = "http://kitwallace.co.uk/poly"  at "lib/poly.xqm";
import module namespace scad = "http://kitwallace.co.uk/scad" at "lib/scad.xqm";

declare function local:coordinate-openscad($solid,$variant) {       
           let $scad-coords := poly:solid-to-openscad($solid)
           let $scad-main := util:binary-to-string(util:binary-doc(concat("/db/apps/3d/openscad/",$variant,".scad")))
           let $scad-functions := util:binary-to-string(util:binary-doc("/db/apps/3d/openscad/functions-v2.scad"))
           return
                    string-join((
                     concat("// ",$solid/name[1]),
                     $scad-coords,
                     $scad-main,
                     $scad-functions
                    ),"&#10;&#10;"
                    )
                 
};

let $forms := ("conway","mccooey","miller")
let $mode := request:get-parameter("mode","index")
let $id :=request:get-parameter("id",())
let $variant := request:get-parameter("variant",())
let $format := request:get-parameter("format",())
return
if ($format = "openscad")

then
   let $solid := poly:solid($id)
   let $openscad := local:coordinate-openscad($solid,$variant)
   let $serialize := util:declare-option("exist:serialize", "method=text media-type=text/text")
   let $header := response:set-header('content-disposition', concat("attachment; filename=",$id,".scad")) 
    return
         $openscad

else
if ($format="xml")
then if ($mode="coordinates")
     then poly:solid($id)
     else ()
else
  let $serialize := util:declare-option("exist:serialize", "method=xhtml media-type=text/html")
  return
<html>
    <head>
        <title>Polyhedra in OpenSCAD</title>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <link href="http://kitwallace.co.uk/rt/images/rticon128.png" rel="icon" sizes="128x128" />
        <link rel="shortcut icon" type="image/png" href="http://kitwallace.co.uk/rt/images/rticon.png"/>
        <style>
              span {{padding-right:15px}}
             .l2 {{font-size:13pt}}
              body {{background-color: #ddfaff}}
        </style>

    </head>
    <body>
        <h1>Polyhedra in OpenSCAD</h1>
        <h2><span><a href="?mode=index">Index</a></span><span><a href="?mode=full">Full List</a></span><span><a href="?mode=about">About</a></span></h2>
        
        <div>
         {if ($mode="about")
          then 
          <div>Polyhedra are defined by several forms:
           <ul>
             <li>Coordinates from David McCooey's  <a href="http://dmccooey.com/polyhedra/">Polyhedra site </a> </li>
             <li>Coordinates for the Johnson solids from George Hart</li>
             <li>Conway formula</li>
             <li>Miller Indices</li>
           </ul>
           This project is discussed in my <a href="http://kitwallace.tumblr.com/tagged/polyhedra">blog.</a>
           </div>     
          else if ($mode ="index")
          then 
           <div>
           <h3>Index</h3>
             <h3>Data</h3>
                <ul>

                  <li><a href="?mode=form&amp;variant=mccooey">McCooey Coordinates</a></li>
                  <li><a href="?mode=form&amp;variant=conway">Conway Formulae</a></li>
                  <li><a href="?mode=form&amp;variant=miller">Miller Indexes</a></li>
                  
                  
                 </ul>
                 <h3>Tags</h3>
                  <ul>
                    {for $tag in distinct-values($poly:solids/solid/tag)
                     order by $tag
                     return
                     <li><a href="?mode=tag&amp;id={$tag}">{$tag}</a></li>
                    }                
                  </ul>
           </div>
           else if ($mode=("tag","form","full"))
           then       
           let $selectedSolids := 
               if ($mode="full")
               then $poly:solids/solid
               else if ($mode = "form") 
               then if ($variant = "miller") 
                    then $poly:solids/solid[miller]
                    else if ($variant ="mccooey")
                    then $poly:solids/solid[dmccooeyid]
                    else if ($variant="conway")
                    then $poly:solids/solid[conway]
                    else ()
               else if ($mode="tag")
               then $poly:solids/solid[tag = $id]
               else ()
               
           return
           <div> 
               <h3>{$mode} : {$id}</h3>
               <table >
               <tr><th>Name</th><th>Other names</th><th>Tags</th><th>#faces</th><th>#vertices</th></tr>
               {for $solid in $selectedSolids
                let $esolid := poly:solid($solid/id)
                order by $solid/name[1]
                return
                  <tr>
                    <th align="left"><a href="?mode=solid&amp;id={$solid/id}">{$solid/name[1]}</a></th>
                    <td>{string-join($solid/name[position() > 1],", ")}</td>
                    <td>{for $tag in $solid/tag where $tag != $id return <span><a href="?mode=tag&amp;id={$tag}">{$tag/string()}</a></span>} </td>
                    <td>{count($esolid/faces/face)}</td>
                    <td>{count($esolid/points/point)}</td>
                    
                  </tr>
              }  
              </table>
           </div>
           else if ($mode="solid") 
           then 
            let $solid := $poly:solids/solid[id=$id]          
            let $coordinates := $poly:coordinates/solid[id=$id]
            let $dual := if ($solid/dual) then $solid/dual
                         else $poly:solids/solid[dual=$id]/id
             return
            <div>
                 <h3>{$solid/name[1]/string()}</h3>
                 <table>
                 
                 {if ($solid/tag) 
                  then <tr><th>Tags</th><td>{for $tag in $solid/tag return <span><a href="?mode=tag&amp;id={$tag}">{$tag/string()}</a ></span>} </td></tr> 
                  else ()
                 }
      
                 {if(exists($solid/name[2])) then <tr><th>Other names</th><td>{for $name in $solid/name[position() > 1] return <span>{$name/string()} {if ($name/@vocab) then concat("[",$name/@vocab,"]") else () }</span>}</td></tr>  else () }
                 {if ($dual) then <tr><th>Dual</th><td><a href="?mode=solid&amp;id={$dual}">{$dual/string()}</a></td></tr>  else ()}
                 {if ($solid/conway) then <tr><th>Conway</th><td>{for $f in $solid/conway/formula return <div><a href="?mode=conway&amp;id={$f}">{$f/string()}</a></div>}</td></tr> else () }
                 {if ($solid/miller) then <tr><th>Miller</th><td>{for $f in $solid/miller/form return <div><a href="?mode=miller&amp;id={$f}">{$f/string()} with symmetry {$f/@base/string()}</a></div>}</td></tr> else () }
                 {if ($coordinates) 
                 then  <tr><th>Coordinates</th><td><span>{count($coordinates//point)} Vertices and {count($coordinates//face)} Faces </span>
                 
                  <span><a href="?id={$id}&amp;mode=coordinates&amp;format=xml">XML</a></span></td></tr>
                 else ()
                 }
                                   { if (exists($solid/model))
                      then <tr><th>3D models</th>
                               <td>{for $model in $solid/model 
                                    order by $model/variant
                                     return 
                                        <div>  <a href="?mode=stl&amp;id={$solid/id}&amp;path={$model/path}">STL {$model/variant/string()}</a> </div>
                                   }     
                           </td></tr>
                      else ()
                  }
<!--               {if ($solid/faces) 
                      then <tr><th>Faces</th><td>{ for $face in $solid//face return <div>{$face/@n/string()} {$face/@shape/string()} faces with {$face/@order/string()} sides</div> }</td></tr>
                      else ()
                  }
                  {if ($solid/vertices) 
                      then <tr><th>Vertices</th><td>{ for $vertex in $solid//vertex return <div>{$vertex/@n/string()} vertices with {$vertex/@order/string()} edges</div> }</td></tr>
                      else ()
                  }
  -->
                  {if ($solid/comment) then <tr><th>Comment</th><td>{$solid/comment/node()}</td></tr> else ()}
                  
                   {if ($solid/dmccooey) 
                   then <tr><th>David Mccooey</th><td><span><a class="external" href="http://dmccooey.com/polyhedra/{$solid/id}.html">Java Applet</a> </span>
                            </td></tr>
                   else () 
                   }
                  <tr><th>Google search</th><td>  <a class="external" href="https://www.google.co.uk/search?q={$solid/name[1]}">Web</a></td></tr>
</table>
<h3>Openscad Generation</h3>

<form action="?">
         <input type="hidden" name="mode" value="coordinates"/>
          Solid id <input type="text" name="id" value="{$solid/id}" />  
          Base <input type="text" name="base" value="{$solid/id}" />
          OpenSCAD <select name="variant">
                      {for $s in ("conway","shell","wire","stellate","antistellate","antistellate-cutout","spherical","modulated-shell","modulated-wire","engrave","spacefill","dual")
                       return
                         element option {
                             attribute value {$s},
                             if ($s = $variant) then attribute selected {"selected"} else (),
                             $s
                         }
                      }
                   </select>
           Output <select name="format"><option value="html">HTML</option><option value="openscad">Download</option></select>
           <input type="submit" name="action" value="Create OpenSCAD"/>
        </form>

  <!--               
                    {for $construct in $solid/construct
                     let $poly := ($construct/polyhedron,$solid/id)[1]
                     return
                        <div>&#160;&#160;&#160;Construct 
                        {if ($poly != $solid/id)
                             then <span>from <a href="?#{$poly}">{$poly/string()}</a> </span>
                             else ()
                        } using <a href="solid-to-scad.xq?id={$solid/id}&amp;base={$poly}&amp;scad={$construct/scad}">{$construct/scad/string()}</a>. &#160;{$construct/code/string()}
                        </div>
                    }
                    
  -->
                 
                </div>
           else if ($mode="stl")
           then
                let $solid := $poly:solids/solid[id=$id]
                let $path := request:get-parameter("path",())
                let $model := $solid/model[path=$path]
                return
                <div>
                  <h3><span><a href="?id={$solid/id}&amp;mode=solid">{$solid/name[1]/string()}</a></span> Variant<span>{$model/variant/string()}</span></h3>
                 
                  <canvas id="3d" width="640" height="480"/>
                  <script type="text/javascript" src="http://kitwallace.co.uk/js/jsc3d.js"/>
                  <script lang="text/javascript">
function init() {{
viewer.setParameter("InitRotationX",-45);
viewer.setParameter("InitRotationY",0);
viewer.setParameter("InitRotationZ",0);
viewer.init();
viewer.update();
}}

var canvas = document.getElementById('3d');
var viewer = new JSC3D.Viewer(canvas);
viewer.setParameter('SceneUrl', 'models/{$path}');
viewer.setParameter('RenderMode', 'flat');
viewer.setParameter('ProgressBar', 'on');
viewer.setParameter("Definition","high");
viewer.setParameter("ModelColor","#B2B2CC");
viewer.setParameter("BackgroundColor1","#FFFFFF");
viewer.setParameter("BackgroundColor2","#FFFFFF");
init();

</script>
        </div> 
 else if ($mode="configure")
 then ()
 else if ($mode="coordinates")
 then    
         let $solid := poly:solid($id)
         let $openscad := local:coordinate-openscad($solid,$variant)  
         return
            <div>
              <h3><span><a href="?id={$id}&amp;mode=solid">{$solid/name[1]/string()}</a></span> Variant <span>{$variant}</span></h3>
              <pre>
                {$openscad}
              </pre>
            </div>
           
      else()
         }
        </div>
    </body>
</html>
