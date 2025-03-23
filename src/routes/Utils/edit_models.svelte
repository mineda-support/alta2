<script lang="ts">
    let { models = $bindable() } = $props();
    console.log('models in EditModels=', $state.snapshot(models));
</script>

<div class="tab-content" style="border:green solid 2px;">
    {#each Object.entries(models) as [model_name, model_params]}
        [{model_name}]<br />
        {#each Object.entries(model_params) as [param]}
            <label
                >{param}:
                <input
                    style="border:darkgray solid 1px;"
                    bind:value={models[model_name][param]}
                /><br /></label
            >
        {/each}
    {/each}
</div>
