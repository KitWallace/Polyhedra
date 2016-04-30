import module namespace poly = "http://kitwallace.co.uk/poly"  at "lib/poly.xqm";
import module namespace log = "http://kitwallace.me/log" at "/db/lib/log.xqm";

let $forms := ("conway","mccooey","miller")
let $mode := request:get-parameter("mode","index")
let $id :=request:get-parameter("id",())
let $variant := request:get-parameter("variant",())
let $q := request:get-parameter("q",())
let $format := request:get-parameter("format","html")
let $logit := log:log-request("3d","solid-index")
return
if ($format = "openscad")
then
   if ($mode = "make")
   then 
       let $solid := poly:solid($id)
       let $cleanid := poly:clean-name($solid/id)
       let $form := request:get-parameter("form",())
       let $openscad := poly:make-openscad($solid)
       return
       if (not(exists($openscad))) 
       then 
       let $serialize := util:declare-option("exist:serialize", "method=text media-type=text/text")
       return <div>no source selected </div>
       else 
       let $serialize := util:declare-option("exist:serialize", "method=text media-type=text/text")
       let $header := response:set-header('content-disposition', concat("attachment; filename=",$cleanid,"-",$form,".scad")) 
       return
           $openscad
   else if ($mode = "makenew")
   then 
       let $solid := element solid {
                          element id  {$id},
                          element name {$id}
                     }
       let $cleanid := poly:clean-name($solid/id)
       let $form := request:get-parameter("form",())
       let $openscad := poly:make-openscad($solid)
       return
       if (not(exists($openscad))) 
       then 
       let $serialize := util:declare-option("exist:serialize", "method=text media-type=text/text")
       return <div>no source selected </div>
       else 
       let $serialize := util:declare-option("exist:serialize", "method=text media-type=text/text")
       let $header := response:set-header('content-disposition', concat("attachment; filename=",$cleanid,"-",$form,".scad")) 
       return
           $openscad
   else ()
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
        <link href="http://kitwallace.co.uk/3d/images/poly128.png" rel="icon" sizes="128x128" />
        <link rel="shortcut icon" type="image/png" href="http://kitwallace.co.uk/3d/images/poly128.png"/>
        <script src="jscripts/sorttable.js"></script>
        <script src="jscripts/poly.js"></script>
         
        <style>
              span {{padding-right:15px}}
             .l2 {{font-size:13pt}}
              body {{background-color: #ddfaff}}
              .right {{position:absolute; top:50px;left:45%}}
              a.external {{
    background-image: url('../../BSA/images/Icon_External_Link.png');
    padding-right: 12px;
    text-decoration: none;
    background-position: right;
    background-repeat:no-repeat;
}}
        </style>

    </head>
    <body>
        <h1>Polyhedra in OpenSCAD</h1>
        <h2><span><a href="?mode=index">Index</a></span><span><a href="?mode=full">Full List</a></span><span><a href="?mode=create">Create Conway</a></span><span><a href="?mode=about">About</a></span>
        <span>Search<form action="?"  style="display:inline"><input type="hidden" name="mode" value="search" /><input type="text" name="q" size="15"  value="{$q}"/></form></span>
        </h2>
        
        <div>
  {if ($mode="about")
   then 
          <div>
          <h3>Overview</h3>
          Polyhedra are defined by several forms:
           <ul>
             <li>Coordinates from David McCooey's  <a href="http://dmccooey.com/polyhedra/">Polyhedra site </a> </li>
             <li>Coordinates for the Johnson solids from George Hart</li>
             <li>Conway formula</li>
             <li>Miller Indices  - under development</li>
           </ul>
           <a href="http://http://www.openscad.org/">OpenSCAD</a> code is generated to create a polyhedron in a number of different forms:
           <ul>
              <li>solid</li>
              <li>wireframe</li>
              <li>open (Leonardo Style) faces</li>
              <li>net</li>
           </ul>
           with optional transforms including distortions, vertex modulation and Catmull-Clark smoothing. <br/>
           
           <h3>Conway operators</h3>
           Conway formula either stored with the polyhedron data or entered manually allow an range of operators identified by a single lower-case (for operators) or upper-case (for primitives).  Each can be parameterised, either with a single number "k5" or full parameters in parentheses "k(fn=5,h=0.5)".
           <table>
           <tr><th>Conway code</th><th>Openscad function</th><th>Parameters</th><th>Canonicalisation</th><th>Description</th></tr>
             {for $operator in $poly:conwayOperators/operator
             return
              <tr><td>{$operator/@char/string()}</td>
                  <td>{$operator/@function/string()}</td>
                  <td>{$operator/@params/string()}</td>
                  <td>{$operator/@post/string()}</td>
                  <td>{$operator/@description/string()}</td>
             </tr>
              }
           </table>
           This project is discussed in my <a href="http://kitwallace.tumblr.com/tagged/polyhedra">blog</a>. Code and outstanding issues are on <a href="https://github.com/KitWallace/Polyhedra">Github</a>.
           For an alternative, interaction Conway formula modeller see the very impressive <a href="http://levskaya.github.io/polyhedronisme/">Polyhedronisme</a>.
           </div>     
 
  else if ($mode ="index")
  then 
       <div>
           <h3>Index</h3>
             <h3>Formulae</h3>
                <ul>
                  <li><a href="?mode=form&amp;variant=conway">Conway Formulae</a></li>
                  <li><a href="?mode=form&amp;variant=miller">Miller Indexes</a></li> 
                 </ul>
                 <h3>Tags</h3>
                  <ul>
                    {for $tag in distinct-values($poly:solids/solid/tag)
                     order by upper-case($tag)
                     return
                     <li><a href="?mode=tag&amp;id={$tag}">{$tag}</a></li>
                    }                
                  </ul>
           </div>
           else if ($mode=("tag","form","full","search"))
           then       
           let $selectedSolids := 
               if ($mode="full")
               then $poly:solids/solid
               else if ($mode = "form") 
               then if ($variant = "miller") 
                    then $poly:solids/solid[miller]
                    
                    else if ($variant="conway")
                    then $poly:solids/solid[conway]
                    else ()
               else if ($mode="tag")
               then $poly:solids/solid[tag = $id]
               else if ($mode="search")
               then $poly:solids/solid[matches(name,$q,"i")]
               else ()
               
           return
           <div> 
               <h3>{$mode} : {$id}  Number = {count($selectedSolids)}</h3>
               <table class="sortable">
                <tr><th>Name</th><th>Tags</th><th>#vertices</th><th>#faces</th><th>face orders</th><th>#edges</th><th>Conway</th></tr>
               {for $solid in $selectedSolids
                let $V := number($solid//Vertices/@count)
                let $F := number(if ($solid//Faces/@count) then $solid//Faces/@count else sum($solid//Face/@count))
                let $E := $V + $F - 2  (:eulers law:)
                order by upper-case($solid/name[1])
                return
                  <tr>
                    <td><b><a href="?mode=solid&amp;id={$solid/id}">{$solid/name[1]/string()}</a></b>&#160;
                     <span>{string-join($solid/name[position() > 1],", ")}</span></td>
                     <td>{for $tag in $solid/tag 
                         where true() (: $tag != $id :)
                         return <span><a href="?mode=tag&amp;id={$tag}">{$tag/string()}</a></span>
                         }
                    </td> 
                    <td>{$V}</td>
                    <td>{$F}</td>
                    <td>{string-join(for $face in $solid//Face return concat($face/@count," of ",$face/@order),",")}</td>
              
                    <td>{$E}</td>
                    <td>{string-join($solid/conway/formula,", ")}</td>
                  </tr>
              }  
              </table>
           </div>
   else if ($mode="solid") 
   then 
            let $solid := poly:solid($id)          
            let $dual := if ($solid/dual) then $solid/dual
                         else $poly:solids/solid[dual=$id]/id
            let $V := number($solid//Vertices/@count)
            let $F := number(if ($solid//Faces/@count) then $solid//Faces/@count else sum($solid//Face/@count))
            let $E := $V + $F - 2  (:eulers law:)
        
             return
            <div>
                 <h3>{$solid/name[1]/string()}</h3>
                 <table>
                 
                 {if ($solid/tag) 
                  then <tr><th>Tags</th><td>{for $tag in $solid/tag return <span><a href="?mode=tag&amp;id={$tag}">{$tag/string()}</a ></span>} </td></tr> 
                  else ()
                 }
              
                 {if(exists($solid/name[2])) then <tr><th>Other names</th><td>{for $name in $solid/name[position() > 1] return <span>{$name/string()} {if ($name/@vocab) then concat("[",$name/@vocab,"]") else () }</span>}</td></tr>  else () }
                 {if ($solid/description) then <tr><th>Description</th><td>{$solid/description/node()}</td></tr> else () }
                 
                
                 
                 {if ($dual) then <tr><th>Dual</th><td><a href="?mode=solid&amp;id={$dual}">{$dual/string()}</a></td></tr>  else ()}
                 {if ($solid/miller) then <tr><th>Miller</th><td>{for $f in $solid/miller/form return <div>{$f/string()} with  {$f/@symmetry/string()} symmetry</div>}</td></tr> else () }
                 { if (exists($solid/model))
                  then <tr>
                           <th>3D models</th>
                           <td>{for $model in $solid/model 
                                order by $model/variant
                                return 
                                 <div>  <a href="?mode=stl&amp;id={$solid/id}&amp;path={$model/path}">STL {$model/variant/string()}</a> </div>
                               }     
                           </td>
                        </tr>
                      else ()
                  }
                  {if ($solid//Vertices) 
                      then <tr><th>Vertices</th><td>{$V} </td></tr>
                      else ()
                  }
                  {if ($solid//Faces) 
                      then <tr><th>Faces</th><td> {$F} : { for $face in $solid//Face return <span>{$face/@count/string()} order {$face/@order/string()}</span> }</td></tr>
                      else ()
                  }
                  {if ($solid//Faces) 
                      then <tr><th>Edges (via Euler)</th><td> {$E}</td></tr>
                      else ()
                  }
          
                  {if ($solid/comment) then <tr><th>Comment</th><td>{$solid/comment/node()}</td></tr> else ()}
                  
                  <tr><th>Links</th><td>
                  {if ($solid/tag="dmccooey") then <div><a class="external"  href="http://dmccooey.com/polyhedra/{$solid/id}.html">David McCooey</a></div> else () }
                  {for $url in $solid/url return <div><a class="external" href="{$url}">{string(($url/@source,"coordinates")[1])}</a></div>}
                  <div> <a class="external" href="https://www.google.co.uk/search?q={$solid/name[1]}">Google Search</a></div>
                 </td></tr>
                 
                   
          </table>
               <div class="right">
               <h3>Generate OpenSCAD</h3>
                 <form action="?" >
         <input type="hidden" name="id" value="{$id}"/>
         <input type="hidden" name="mode" value="make"/>
         
         <table border="1">
         <tr><td colspan="2"  style="text-align:center"><b>Coordinate Source</b></td></tr>
         {if ($solid/points) then <tr><th>Coordinates <input type="radio" name="src" value="coordinates" checked="checked">
          </input> </th> <td><span>{count($solid//point)} Vertices and {count($solid//face)} Faces </span></td></tr> else () }
         <tr><th>Conway  <input type="radio" name="src" value="conway">{if (not ($solid/points)) then attribute checked {"checked"} else () }</input>
                 </th><td>  Formula  
                            {if (count($solid/conway/formula) > 1)                           
                            then <select name="conway1"><option value=""> select formula</option>{for $f in $solid/conway/formula return <option>{$f}</option>}</select> 
                            else ()
                            }
                            <input type="text" name="conway2" size ="25"  value="{if (count($solid/conway/formula)=1) then $solid/conway/formula else ()}"/> 
                            Simple Canonical <input type="text" name="plane" value="{if($solid/conway/formula/@canonical='no') then 0 else 10}" size="5"/> 
                            True Canonical <input type="text" name="canon" value="0" size="5"/>
         </td></tr> 
         <tr><td colspan="2" style="text-align:center"><b >Transformations</b></td></tr>
  
         <tr><th>Skew (degrees)</th><td> Alpha <input type="text" name="skew-alpha" value="0" size="5"/>  Beta <input type="text" name="skew-beta" value="0" size="5"/>
         </td>
         </tr>
          
         <tr><th>Vertex scaling </th><td>  X <input type="text" name="scale-x" value="1" size="5"/> Y <input type="text" name="scale-y" value="1" size="5"/> Z <input type="text" name="scale-z" value="1" size="5"/>
         </td>
         </tr>
         <tr><th>Vertex spherical modulation</th><td>r is radial distance, theta is polar angle (0.180), phi is azimuth (0..360)<br/>
         <select id="selectFunction" name="selectFunction" onchange="setFunctionText()"><option value="">select/clear function</option>{for $f in $poly:modulations/modulation return <option value="{$f/name}">{$f/name/string()}</option>}</select>
         <textarea type="text" id="functionText" name="functionText" cols="60" rows="4">
</textarea></td></tr>
         <tr><th>Place on largest face </th><td> Yes <input type="radio" name="place" value="yes" checked="checked"/>No <input type="radio" name="place" value="no"/></td></tr>
       
         <tr><th  title="takes ages for al but small numbers of faces">Catmull-Clark smoothing</th><td> number of iterations <input type="text" name="catmull-clark-n" value="0" size="5"/></td></tr>
         <tr><th>Overall Scale </th><td> <input type="text" name="scale" value="20" size="5"/></td></tr>
         <tr><td colspan="2" style="text-align:center"><b>Form</b></td></tr>
         <tr><th>Solid <input type="radio" name="form" value="solid"  checked="true"/>  </th><td></td></tr>
         
         <tr><th>Wire frame <input type="radio" name="form" value="wire"/></th>
         <td>Edge Radius <input type="text" name="edge-radius" value="0.02" size="5"/> Vertex Radius <input type="text" name="vertex-radius" value="" size="5"/>  # Sides <input type="text" name="edge-sides" value="10" size="5"/>
         </td>
         </tr>
         <tr><th>Open Faces <input type="radio" name="form" value="openface"/></th><td> Depth <input type="text" name="depth" value="0.3" size="5"/> Outer inset ratio <input type="text" name="outer-inset-ratio" value="0.3" size="5"/> Inner inset ratio <input type="text" name="inner-inset-ratio" value="0.3" size="5"/>  Open Faces (default all)<input type="text" name="cut-faces" value="" size="5"/>    
         </td>
         </tr>
         <tr><th>Net <input type="radio" name="form" value="net"/> </th>
               <td>Thickness <input type="text" name="thickness" size="5" value="0.1" /> Openness (0-1)<input type="text" name="openness" value="0" size="5"/></td></tr> 
    
           <tr><td colspan="2" style="text-align:center"><b>Output</b></td></tr>
         <tr><th>
         Format </th><td><select name="format"><option value="openscad">OpenSCAD</option><option value="html">HTML</option></select>
          </td></tr>
          
         <tr><td colspan="2" style="text-align:center"><input type="submit" name="submit" value="Generate"/></td></tr> 
         </table>
         </form>  
         <div id ="functionTexts" style="display:none">
           {for $f in $poly:modulations/modulation 
            return <div>function fmod(r,theta,phi) =  // {$f/name/string()}&#10;{$f/function/string()};</div>
           }
         </div>
       </div>
    </div>
  else if ($mode="create")
  then 
     <div>
     <h3>Define polyhedron by Conway formula</h3>
     <div> see <a href="?mode=about">About</a> for the format and operators</div>
        <form action="?" >
         <input type="hidden" name="mode" value="makenew"/>  
         <table border="1">
         <tr><th>Name</th><td><input type="text" name="id" size="30"/></td></tr>
         <tr><th>Conway</th><td>Formula 
                            <input type="text" name="conway2" size ="25"/> 
                            Simple Canonical <input type="text" name="plane" value="0" size="5"/> 
                            True Canonical <input type="text" name="canon" value="0" size="5"/>
         </td></tr> 
         <tr><td colspan="2" style="text-align:center"><b >Transformations</b></td></tr>
  
         <tr><th>Skew (degrees)</th><td> Alpha <input type="text" name="skew-alpha" value="0" size="5"/>  Beta <input type="text" name="skew-beta" value="0" size="5"/>
         </td>
         </tr>
          
         <tr><th>Vertex scaling </th><td>  X <input type="text" name="scale-x" value="1" size="5"/> Y <input type="text" name="scale-y" value="1" size="5"/> Z <input type="text" name="scale-z" value="1" size="5"/>
         </td>
         </tr>
         <tr><th>Vertex spherical modulation</th><td>r is radial distance, theta is polar angle (0.180), phi is azimuth (0..360)<br/>
         <select id="selectFunction" name="selectFunction" onchange="setFunctionText()"><option value="">select/clear function</option>{for $f in $poly:modulations/modulation return <option value="{$f/name}">{$f/name/string()}</option>}</select>
         <textarea type="text" id="functionText" name="functionText" cols="60" rows="4">
          </textarea></td></tr>
         <tr><th>Place on largest face </th><td> Yes <input type="radio" name="place" value="yes" checked="checked"/>No <input type="radio" name="place" value="no"/></td></tr>
       
        <tr><th  title="takes ages for al but small numbers of faces">Catmull-Clark smoothing</th><td> number of iterations <input type="text" name="catmull-clark-n" value="0" size="5"/></td></tr>
         <tr><th>Overall Scale </th><td> <input type="text" name="scale" value="20" size="5"/></td></tr>
         <tr><td colspan="2" style="text-align:center"><b>Form</b></td></tr>
         <tr><th>Solid <input type="radio" name="form" value="solid"  checked="true"/>  </th><td></td></tr>
         
         <tr><th>Wire frame <input type="radio" name="form" value="wire"/></th>
         <td>Edge Radius <input type="text" name="edge-radius" value="0.02" size="5"/> Vertex Radius <input type="text" name="vertex-radius" value="0.02" size="5"/>  # Sides <input type="text" name="edge-sides" value="10" size="5"/>
         </td>
         </tr>
         <tr><th>Open Face <input type="radio" name="form" value="openface"/></th><td> Depth <input type="text" name="depth" value="0.3" size="5"/> Outer inset ratio <input type="text" name="outer-inset-ratio" value="0.3" size="5"/> Inner inset ratio <input type="text" name="inner-inset-ratio" value="0.3" size="5"/>  Open Faces (default all)<input type="text" name="open-faces" value="" size="5"/>    
         </td>
         </tr>
         <tr><th>Net <input type="radio" name="form" value="net"/> </th>
               <td>Thickness <input type="text" name="thickness" size="5" value="0.1" /> Openness (0-1)<input type="text" name="openness" value="0" size="5"/></td></tr> 
    
           <tr><td colspan="2" style="text-align:center"><b>Output</b></td></tr>
         <tr><th>
         Format </th><td><select name="format"><option value="openscad">OpenSCAD</option><option value="html">HTML</option></select>
          </td></tr>
          
         <tr><td colspan="2" style="text-align:center"><input type="submit" name="submit" value="Generate"/></td></tr> 
         </table>
         </form>    
         <div id ="functionTexts" style="display:none">
           {for $f in $poly:modulations/modulation 
            return <div>function fmod(r,theta,phi) =  // {$f/name/string()}&#10;{$f/function/string()};</div>
           }
         </div>
     
     
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

<div><a href="models/{$path}">Download STL </a></div>
        </div> 
 
 else if ($mode = "make")
 then  let $solid := poly:solid($id)
       let $openscad := poly:make-openscad($solid)
       return
           <div>
             <h3>Generated OpenSCAD code for {$solid/name[1]/string()} </h3>
             <pre>{$openscad}</pre>
           </div>
           
           
 else if ($mode = "makenew")
 then 
       let $solid := element solid {
                          element id  {$id},
                          element name {$id}
                     }
       let $openscad := poly:make-openscad($solid)
       return
           <div>
             <h3>Generated OpenSCAD code for {$solid/name[1]/string()} </h3>
             <pre>{$openscad}</pre>
           </div>
 else ()          
 
         }
        </div>
    </body>
</html>
