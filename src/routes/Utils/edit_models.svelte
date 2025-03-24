<script lang="ts">
    import { tooltip, msg } from "./tooltip.svelte";
    let { models = $bindable(), filter = $bindable() } = $props();
    console.log("models in EditModels=", $state.snapshot(models));
    let filter_on = $state(true);
</script>

<div class="tab-content" style="border:green solid 2px;">
    {#each Object.entries(models) as [model_name, model_params]}
        <div style="text-align:right;">
            <label use:tooltip={() => msg("filter on/off")}>
                Filter:<input value={filter} /><input
                    type="checkbox"
                    bind:checked={filter_on}
                /></label
            >
        </div>
        [{model_name}]<br />
        {#each Object.entries(model_params) as [param]}
            {#if filter == undefined || filter == "" || param.match(/${filter}/)}
                <label
                    >{param}:
                    <input
                        style="border:darkgray solid 1px;"
                        bind:value={models[model_name][param]}
                    /><br /></label
                >
            {/if}
        {/each}
    {/each}
</div>
