<input type="text" id="rtl1" placeholder="Renk">
<div style="display:flex">
<div  style="width:400px">
    <ul  class='sortablea connectedSortable' id="dxx1"><ul>
   
</div>
<div id="dxx2"  style="width:400px">
 <ul style="border:solid" id="sortable2" class="list-group sortablea  connectedSortable"></ul>
</div>
</div>
<style>
ul{margin-top:0;margin-bottom:0}
</style>

<script>


var itemsDriveC = [];
$("#rtl1").keydown(function (e) {
    console.log(e)
    if (e.keyCode == 13) {
        var elem = document.getElementById("rtl1")
setC(elem)
    }

})

function setC(elem) {
    console.log(elem)
    var keyword = $(elem).val()
    itemsDriveC=[];
    if (keyword.length > 3) {
        $.ajax({
            url: "/cfc/boyahane.cfc?method=getProdTreeWithName&keyword=" + keyword,
            success: function (retDat) {
             //   console.log(JSON.parse(retDat.toLowerCase()))
                var aaa = JSON.parse(retDat.toLowerCase());
                for (let i = 0; i < aaa.length; i++) {
                    var obj = new Object;
                    obj.name = aaa[i].name;
                    if (aaa[i].parentid) {
                        obj.parentId = aaa[i].parentid;
                    }
                    obj.icon = aaa[i].icon;
                    obj.id = aaa[i].id;
                    obj.isDirectory = aaa[i].isdirectory;
                    obj.product_unit_id=aaa[i].product_unit_id;
                    obj.product_code=aaa[i].product_code;
                    obj.main_unit=aaa[i].main_unit;
                    obj.expanded = aaa[i].expanded;
                    itemsDriveC.push(obj)
                }
                $("#dxx1").empty()
               makeTree()

            }
        });
    }
   // console.log(itemsDriveC)
   // makeTree()
}
function makeTree(){
    
    for(let i=0;i<itemsDriveC.length;i++){
        //  console.log(itemsDriveC[i])
        if(itemsDriveC[i].isDirectory && !itemsDriveC[i].parentId){
            $("#dxx1").append("<li><ul class='list-group sortablea connectedSortable'><li   class='list-group-item' id='level_"+itemsDriveC[i].id+"'><i id='ikon1' onclick='hideSubs(this.parentElement)' class='fas fa-caret-down'></i>"+itemsDriveC[i].name+" <i style='float:right' class='fas fa-plus'></i></li></ul></li>")
            console.log("state1")
        }else{
            if(itemsDriveC[i].parentId){
                 $("#level_"+itemsDriveC[i].parentId).append("<li class='list-group-item ' id='level_"+itemsDriveC[i].id+"'>"+itemsDriveC[i].name+"<input type='text' style='width:50px !important;float:right' name='tx_"+itemsDriveC[i].id+"'></li>")
                 console.log("state2")
            }else{
                 $("#dxx1").append("<li class='list-group-item id='level_"+itemsDriveC[i].id+"'>"+itemsDriveC[i].name+"</li>")
                 console.log("state3")
            }
        }
    }
}
function hideSubs(elem){
    $(elem).children().find($("li")).toggle(500)
}
  $( function() {
    $( ".sortablea" ).sortable({
      connectWith: ".connectedSortable"
    }).disableSelection();
  } );
  function revize(){
      $( ".sortablea" ).sortable({
      connectWith: ".connectedSortable"
    }).disableSelection();
  }
</script>