<cfprocessingdirective pageEncoding="utf-8">
<!---
    Merkezi makine durum kodları.
    STATUS_OK = 1: Makine çalışır/arıza yok.
    STATUS_MAINTENANCE = 2: Makine bakımda veya bakım sonucu takip gerektiriyor.
    STATUS_FAULT = 3: Makinede aktif arıza var.
--->
<cfscript>
STATUS_OK = 1;
STATUS_MAINTENANCE = 2;
STATUS_FAULT = 3;

machineStatusDefinitions = {};
machineStatusDefinitions[STATUS_OK] = {
    name = "STATUS_OK",
    label = "Çalışıyor",
    legendLabel = "Çözüldü",
    summaryClass = "ok",
    tileClass = "sb-tile-ok",
    icon = "fa-circle-check",
    color = "##16a34a"
};
machineStatusDefinitions[STATUS_MAINTENANCE] = {
    name = "STATUS_MAINTENANCE",
    label = "Bakımda",
    legendLabel = "Bakımda",
    summaryClass = "maint",
    tileClass = "sb-tile-maint",
    icon = "fa-tools",
    color = "##4b5563"
};
machineStatusDefinitions[STATUS_FAULT] = {
    name = "STATUS_FAULT",
    label = "Arızalı",
    legendLabel = "Arızalı",
    summaryClass = "fault",
    tileClass = "sb-tile-fault",
    icon = "fa-triangle-exclamation",
    color = "##dc2626"
};

machineStatusInactive = {
    label = "Pasif",
    summaryClass = "inactive",
    tileClass = "sb-tile-inactive",
    icon = "fa-circle-pause",
    color = "##6b7280"
};

machineFaultStageDefinitions = {
    assigned = {
        label = "Personel Atandı",
        tileClass = "sb-tile-assigned",
        icon = "fa-user-check",
        color = "##1d4ed8"
    },
    intervention = {
        label = "Müdahale Ediliyor",
        tileClass = "sb-tile-intervention",
        icon = "fa-screwdriver-wrench",
        color = "##ca8a04"
    }
};
</cfscript>
