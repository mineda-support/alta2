import fs from 'fs';
import { globSync } from 'node:fs'
import path from 'path';
import { json } from '@sveltejs/kit';

export function GET({ url }) {
    console.log('URL=', url);
    const flow_name = url.searchParams.get('flow_name');
    const dir = url.searchParams.get('dir');
    const json_file = dir + flow_name + '.json';
    console.log(json_file);
    const flow_settings = JSON.parse(fs.readFileSync(json_file));
    return json(flow_settings);
}

export async function POST({ request, cookies }) {
    // console.log(request);
	const props = await request.json();
    const wdir = props.wdir;
    const flow_name = props.flow_name;
    console.log(wdir);
    fs.writeFileSync(wdir+`${flow_name}.json`, JSON.stringify(props));
    console.log(props);
    const flow_files = globSync(wdir + '*.json');
	return json(flow_files.map(a => path.basename(a).replace('.json', '')), { status: 201 });
}
