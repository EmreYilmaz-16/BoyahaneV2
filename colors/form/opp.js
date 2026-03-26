var itemsDriveC = [];
var itemsDriveD = [];
$(function () {
    console.log("main Sort")
    var levelim = 0;
    $("#ul1,#ul2,#ul3,.mylevel").sortable({
        connectWith: ".su1",
        receive: function (e, u) {
            console.log("main Sorts")
            if ($(u.sender[0]).is($("#ul1"))) {
                if ($(e.target).is("#ul3")) {
                    console.log("hedef ul1 > ul 3")
                } else {
                    console.log("hedef ul1 > !ul3")
                }
                tasi(1, $(u.item).data("id"), levelim);
            } else if ($(u.sender[0]).is($("#ul3"))) {
                tasi(2, $(u.item).data("id"), levelim, 'main sort sender ul3');
            } else {
                if ($(e.target).is("#ul1")) {
                    console.log(e.target.parentElement)
                } else if ($(e.target).is("#ul3")) {

                } else {
                    console.log(e.target.parentElement)
                }
                console.log(e)
                console.log(u)
            }
        },
    });
});
function removeTh(elem, t) {
    if (t == 1) { } else if (t == 2) {
        itemsDriveD[ind].amount = vals;
    } else { }
    $(elem.parentElement).remove();
}
function genRow(id, parent_id, name, is_parent, idx, amo, plc) {
    var row = "";
    if (!is_parent) {
        row += '<li data-id="' + id + '" class="list-group-item">';
        row +=
            '<input onchange="IndexDegis(' + idx + ',' + plc + ',this)" data-index="' + idx + '" class="form-control form-control-sm" style="width:25px;float:left" type="text" value="' + idx + '" name="opsira_' +
            parent_id +
            "_" +
            id +
            '">';
        row += name;
        row +=
            ' <button style="float:right" class="btn btn-sm btn-outline-danger" onclick="removeTh(this,' + plc + ')">Sil</button>';
        row +=
            '<input onchange="miktarDegis(' + idx + ',' + plc + ',this)" data-index="' + idx + '" class="form-control form-control-sm" type="text" style="width:45px;float:right"  value="' + amo + '" name="amount_' +
            parent_id +
            "_" +
            id +
            '">';
    } else {
        row += '<li data-id="' + id + '"  class="list-group-item supercl"><button class="btn btn-outline-primary btn-sm" onclick="hideerr(this)"><i class="fas fa-chevron-down""></i></button>&nbsp;';
        row += name;
        row += '<ul class="mylevel su1 list-group " id="level_' + id + '"></ul>';
        row += "</li>";
    }
    return row;
}
$("#rtl1").keydown(function (e) {
    if (e.keyCode == 13) {
        getData();
    }
})
function getData() {
    var keyword = $("#rtl1").val();
    itemsDriveC = [];
    $.ajax({
        url: "/cfc/boyahane.cfc?method=getProdTreeWithName&keyword=" + keyword,
        success: function (retDat) {
            var aaa = JSON.parse(retDat.toLowerCase());
            for (let i = 0; i < aaa.length; i++) {
                var obj = new Object();
                obj.name = aaa[i].name;
                if (aaa[i].parentid) {
                    obj.parentId = aaa[i].parentid;
                }
                obj.icon = aaa[i].icon;
                obj.id = aaa[i].id;
                obj.isDirectory = aaa[i].isdirectory;
                obj.product_unit_id = aaa[i].product_unit_id;
                obj.product_code = aaa[i].product_code;
                obj.main_unit = aaa[i].main_unit;
                obj.expanded = aaa[i].expanded;
                obj.idx = i;
                obj.amount = aaa[i].amount;
                itemsDriveC.push(obj);
            }
            AgacOlustur(1, 'getData');
        },
    });
}
function AgacOlustur(tip = 1, ff) {
    if (tip == 1) {
        $("#ul1").empty();
        for (let i = 0; i < itemsDriveC.length; i++) {
            if (itemsDriveC[i].isDirectory && !itemsDriveC[i].parentId) {
                var row = genRow(itemsDriveC[i].id, 0, itemsDriveC[i].name, true, i, itemsDriveC[i].amount, 1);
                $("#ul1").append(row);

            } else {
                if (itemsDriveC[i].parentId) {
                    var row = genRow(
                        itemsDriveC[i].id,
                        itemsDriveC[i].parentId,
                        itemsDriveC[i].name,
                        false,
                        i,
                        itemsDriveC[i].amount,
                        1
                    );
                    $("#level_" + itemsDriveC[i].parentId).append(row);
                    makesortable("level_" + itemsDriveC[i].parentId);
                } else {
                    var row = genRow(itemsDriveC[i].id, 0, itemsDriveC[i].name, false, i, itemsDriveC[i].amount, 1);
                    $("#ul1").append(row);
                }
            }
        }
    } else {
        $("#ul3").empty();
        for (let i = 0; i < itemsDriveD.length; i++) {
            if (itemsDriveD[i].isDirectory && !itemsDriveD[i].parentId) {
                /*MAİNE YARI MAMÜL ATILIYORSA*/
                var row = genRow(itemsDriveD[i].id, 0, itemsDriveD[i].name, true, i, itemsDriveD[i].amount, 2);
                $("#ul3").append(row);
                console.log("option1")
            } else if (itemsDriveD[i].isDirectory && itemsDriveD[i].parentId) {
                /*YARI MAMÜLE YARI MAMÜL ATILIYORSA*/
                console.log("option1-1")
                var row = genRow(itemsDriveD[i].id, itemsDriveD[i].parentId, itemsDriveD[i].name, true, i, itemsDriveD[i].amount, 2);
                $("#level_" + itemsDriveD[i].parentId).append(row);
                console.log("ikisidevar")
            } else {
                if (itemsDriveD[i].parentId) {
                    /*EKLENEN YARI MAMÜLÜN İÇİNE EKLENİYORSA*/
                    var row = genRow(
                        itemsDriveD[i].id,
                        itemsDriveD[i].parentId,
                        itemsDriveD[i].name,
                        false,
                        i,
                        itemsDriveD[i].amount,
                        2
                    );
                    $("#level_" + itemsDriveD[i].parentId).append(row);
                    console.log("option2")
                    makesortable("level_" + itemsDriveD[i].parentId);
                } else {
                    /*HAM MADDE MAİNE EKLENİYORSA*/
                    var row = genRow(itemsDriveD[i].id, 0, itemsDriveD[i].name, false, i, itemsDriveD[i].amount, 2);
                    $("#ul3").append(row);
                    console.log("option3")
                }
            }
        }
    }
}
function makesortable(id) {
    var elem = document.getElementById(id);
    var levelim = 0;
    $(elem).sortable({
        connectWith: ".su1",
        receive: function (e, u) {
            console.log("sub Sort")
            if ($(u.sender[0]).is($("#ul1"))) {
                if ($(e.target).is("#ul3")) {
                } else {
                    var hedef = $(e.target);
                    levelim = $(hedef).parent().data("id")

                }
                tasi(1, $(u.item).data("id"), levelim);
            } else if ($(u.sender[0]).is($("#ul3"))) {
                if ($(e.target).is("#ul3")) {
                } else {
                    var hedef = $(e.target);
                    levelim = $(hedef).parent().data("id")
                }

                if ($(e.target.parentElement.parentElement[0]).is($(u.sender[0]))) {
                    console.log("makesort Sor=2")
                    tasi(2, $(u.item).data("id"), levelim, 'makesort sender ul3');
                } else {
                    if ($(e.target.parentElement.parentElement).is($("#ul3"))) {
                        console.log("makesort Sor=3")
                        tasi(3, $(u.item).data("id"), levelim, 'makesort sender ul3');
                    } else {
                        console.log("makesort Sor=4")
                        tasi(4, $(u.item).data("id"), levelim, 'makesort sender ul3');
                    }
                }
            } else {
                console.log("başka bişi")
            }
        },
        stop: function (e, u) {

            idxI = $(u.item).index()
            idxItem = $(u.item).children()[0];
            $(idxItem).val(idxI + 1)
        }
    });
}
function reDrawTree() { }
function sil(arr, arr2, id, level) {
    console.log("Id=" + id + "Level=" + level)
    for (var i = 0; i < arr.length; i++) {

        console.log("***BAŞLA***")
        console.log("Calışılan Eleman" + arr[i].name)

        if (arr[i].parentId === id || arr[i].id === id) {
            if (level == 0) {
                console.log("Sanırım Burda bana Bişi Oldu")
                arr2.push(arr[i]);
                arr.splice(i, 1);
                i--;
            } else {
                /*  console.log("SİL ELSE")
                  console.warn("1")
                  console.log(arr)
                  console.log(arr2)*/
                console.log("Array 1")
                console.log(arr[i])
                if (arr[i].parentId != level) {
                    console.log("e-1")
                    if (arr[i].isDirectory) {
                        console.log("e-1-1")
                        arr[i].parentId = level;
                    }else{
                        console.log("e-1-2")
                      //  arr[i].parentId = level;
                    }
                } else {
                    console.log("e-2")
                    arr[i].parentId = level;
                }

                if (arr != arr2) {
                    console.log("arrayler elşt değil")
                    if (arr[i].parentId != level) {
                        console.log("e 2-1")
                    } else {

                        arr[i].parentId = level;
                        console.log("e 2-1-1")
                    }

                    arr2.push(arr[i]);
                    arr.splice(i, 1);

                    i--;
                } else {
                    if (arr[i].parentId != level) {
                        if (arr[i].isDirectory) {
                            arr[i].parentId = level;
                        }
                    } else {
                        arr[i].parentId = level;
                    }

                    i--;
                }
                /* console.warn("2")
                 console.log(arr)
                 console.log(arr2)*/
                i++
            }
            //console.log("Array 2")
            //console.log(arr[i])
            //console.log(i)
            console.log("***BİTİŞ***")
        }
    }
}
function tasi(sor, order, level, gelenyer) {
    console.log("TASI(sor, order,level)")
    console.log("TASI (" + sor + "," + order + "," + level + ")")
    console.log("GELEN - " + gelenyer)
    if (sor === 1) {
        var iid = parseInt(order);
        sil(itemsDriveC, itemsDriveD, iid, level);
    } else if (sor === 2) {
        var iid = parseInt(order);
        sil(itemsDriveD, itemsDriveC, iid, level);
    } else if (sor === 3) {
        var iid = parseInt(order);
        sil(itemsDriveD, itemsDriveD, iid, level);
    } else if (sor === 4) {
        var iid = parseInt(order);
        sil(itemsDriveC, itemsDriveC, iid, level);
    }
    AgacOlustur(2, 'tasi');
}
function miktarDegis(ind, t, elem) {
    var vals = $(elem).val();
    if (t == 1) { } else if (t == 2) {
        itemsDriveD[ind].amount = vals;
    } else { }
}
function IndexDegis(ind, t, elem) {
    var vals = $(elem).val();
    if (t == 1) {

    } else if (t == 2) {
        var temp = itemsDriveD[ind];
        itemsDriveD[ind] = itemsDriveD[vals]
        itemsDriveD[vals] = temp
    } else { }
}

function SaveTree() {
    $.ajax({
        type: "get",
        url: "/cfc/boyahane.cfc?method=saveTree",
        data: JSON.stringify(itemsDriveD),
        dataType: "json",
        success: function (sum) {
            // Store the respone in the DOM.
            console.log(sum)
        }
    });
}

$(".supercl").click(function () {
    $(this.children).toggle();
})

function hideerr(elem) {
    $(elem.parentElement.children[1].children).toggle()
    //$(this.parentElement.children).toggle()
}