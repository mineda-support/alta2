<script>
    import Plot from "svelte-plotly.js";

    export let db_data;
    export let ph_data;
    export let title;
    export let title_x;
    export let title_y1;
    export let title_y2;
</script>

<Plot
    data={db_data}
    layout={{
        title: title,
        xaxis: {
            type: "log",
            autorange: "true",
            linewidth: 1,
            mirror: true,
        },
        yaxis: {
            autorange: "true",
            linewidth: 1,
            mirror: true,
            title: title_y1,
        },
        margin: { t: 30 },
    }}
    fillParent="width"
    debounce={250}
/>
<Plot
    data={ph_data}
    layout={{
        xaxis: {
            type: "log",
            autorange: "true",
            linewidth: 1,
            mirror: true,
            title: title_x,
        },
        yaxis: {
            autorange: "true",
            linewidth: 1,
            mirror: true,
            title: title_y2,
        },
        margin: { t: 30 },
    }}
    fillParent="width"
    debounce={250}
/>
