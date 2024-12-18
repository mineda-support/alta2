<script>
    import Plot from "svelte-plotly.js";
    export let plot_data;
    export let title, performance;
    export let sweep_name;
</script>

<Plot
    data={plot_data}
    layout={{
        title: title,
        xaxis: {
            title:  sweep_name ,
            autorange: "true",
            linewidth: 1,
            mirror: true,
        },
        yaxis: {
            title: performance,
            autorange: "true",
            linewidth: 1,
            mirror: true,
        },
    }}
    fillParent="width"
    debounce={250}
/>
