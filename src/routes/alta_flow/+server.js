import fs from 'fs';
import { globSync } from 'node:fs'
import path from 'path';
import { json } from '@sveltejs/kit';
import yaml from "js-yaml";

export function GET({ url }) {
    console.log('URL=', url);
    const flow_name = url.searchParams.get('flow_name');
    const dir = url.searchParams.get('dir');
    const yaml_file = path.join(dir, flow_name) + '.yaml';
    console.log('flow file=', yaml_file);
    const flow_settings = yaml.load(fs.readFileSync(yaml_file, 'utf8'));
    return json(flow_settings);
}

export async function POST({ request, cookies }) {
    // console.log(request);
	const props = await request.json();
    const wdir = props.wdir;
    const flow_name = props.flow_name;
    console.log(wdir);
    fs.mkdirSync(wdir, { recursive: true });
    fs.writeFileSync(wdir+`${flow_name}.yaml`, yaml.dump(props));
    console.log(props);
    const flow_files = globSync(wdir + '*.yaml');
	return json(flow_files.map(a => path.basename(a).replace('.yaml', '')), { status: 201 });
}

export async function DELETE({ url }) {
    console.log('URL=', url);
    const flow_name = url.searchParams.get('flow_name');
    const dir = url.searchParams.get('dir');
    const yaml_file = dir + flow_name + '.yaml';
    console.log(yaml_file); 
    fs.unlinkSync(yaml_file);
    return json({ message: 'Flow deleted successfully' });
}