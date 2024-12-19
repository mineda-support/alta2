<script lang="ts">
    import Plot from "svelte-plotly.js";
    let {
        plot_data,
        title,
        performance,
        sweep_name
    } = $props();
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
