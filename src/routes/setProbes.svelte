<script lang="ts">
    import { tooltip, msg } from "./Utils/tooltip.svelte";
    let { probes = $bindable(), current_plot = $bindable() } = $props();
    import { proj, ckt } from "./shared.svelte";
    function push_button(node) {
        console.log(`${probes}, ${node}`);
        if (probes == null || probes == undefined || probes == "") {
            probes = node;
        } else {
            probes = probes + ", " + node;
        }
    }
</script>

{#if ckt != undefined}
    [Probes list (clicked probe will be put in probes for a current plot)]
    <div class="sample">
        {#each ckt.info as node}
            <button
                use:tooltip={() =>
                    msg("push probe in probes for a current plot")}
                onclick={() => push_button(node)}
                class="button-item">{node}</button
            >
        {/each}
    </div>
{/if}

<style>
    .sample {
        display: flex;
        flex-wrap: wrap;
        /* border: green solid 5px; */
        height: 200px;
        /* background:yellow; */
        overflow: scroll;
    }
    .box-item {
        width: 25%;
        background: orange;
        text-align: left;
        padding: 5px 10px;
        border: 5px solid #ddd;
    }
    .button-item {
        /* width: 25%; */
        background: lightblue;
        text-align: left;
        padding: 2px 3px;
        border: 2px solid yellow;
    }
</style>
