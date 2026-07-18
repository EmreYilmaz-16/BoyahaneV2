/* Shared status board state colors */
.sb-page {
    --sb-color-ok-start: ##22c55e;
    --sb-color-ok-end: ##15803d;
    --sb-color-ok-legend: ##16a34a;
    --sb-color-maint-start: ##9ca3af;
    --sb-color-maint-end: ##4b5563;
    --sb-color-maint-legend: ##4b5563;
    --sb-color-assigned-start: ##60a5fa;
    --sb-color-assigned-end: ##1d4ed8;
    --sb-color-assigned-legend: ##1d4ed8;
    --sb-color-intervention-start: ##facc15;
    --sb-color-intervention-end: ##ca8a04;
    --sb-color-intervention-legend: ##ca8a04;
    --sb-color-fault-start: ##f87171;
    --sb-color-fault-end: ##b91c1c;
    --sb-color-fault-legend: ##dc2626;
    --sb-color-inactive-start: ##cbd5e1;
    --sb-color-inactive-end: ##64748b;
    --sb-color-inactive-legend: ##64748b;
}

.sb-tile-ok { background: linear-gradient(160deg, var(--sb-color-ok-start) 0%, var(--sb-color-ok-end) 100%); }
.sb-tile-maint { background: linear-gradient(160deg, var(--sb-color-maint-start) 0%, var(--sb-color-maint-end) 100%); }
.sb-tile-assigned { background: linear-gradient(160deg, var(--sb-color-assigned-start) 0%, var(--sb-color-assigned-end) 100%); }
.sb-tile-intervention { background: linear-gradient(160deg, var(--sb-color-intervention-start) 0%, var(--sb-color-intervention-end) 100%); color: ##1f2937; }
.sb-tile-fault { background: linear-gradient(160deg, var(--sb-color-fault-start) 0%, var(--sb-color-fault-end) 100%); }
.sb-tile-inactive { background: linear-gradient(160deg, var(--sb-color-inactive-start) 0%, var(--sb-color-inactive-end) 100%); }

.sb-legend-dot-ok { background: var(--sb-color-ok-legend); }
.sb-legend-dot-maint { background: var(--sb-color-maint-legend); }
.sb-legend-dot-assigned { background: var(--sb-color-assigned-legend); }
.sb-legend-dot-intervention { background: var(--sb-color-intervention-legend); }
.sb-legend-dot-fault { background: var(--sb-color-fault-legend); }
.sb-legend-dot-inactive { background: var(--sb-color-inactive-legend); }
