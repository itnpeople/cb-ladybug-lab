import { select, json, geoPath, geoMercator, zoom } from "d3";
import d3Tip from "d3-tip";
//import { feature } from "topojson";
import REGIONS from "./regions.json"

require("./map.css");


export class Lang {
	
	public static toNumber(n:any, d:number):number {
		if(typeof(n) == "string") n = n.replace(/\px/g,'')
		return Lang.isNumber(n)? Number.parseFloat(n): (d?d:0);
	}
	public static isNumber(n:any):boolean{
		return !isNaN(parseFloat(n)) && isFinite(n);
	}

}

export class Bounds {
	public left:number = 0;
	public right:number = 0;
	public bottom:number = 0;
	public top:number = 0;
	public width:number = 0;
	public height:number = 0;

	constructor(selection:d3.Selection<SVGElement, any, Element, any>) {
		let bounds:ClientRect =  selection.node().getBoundingClientRect();

		// padding 반영
		this.left = bounds.left + Lang.toNumber(selection.style("padding-left"),0);
		this.right = bounds.right - Lang.toNumber(selection.style("padding-right"),0);
		this.top = bounds.top + Lang.toNumber(selection.style("padding-top"),0);
		this.bottom = bounds.bottom - Lang.toNumber(selection.style("padding-bottom"),0);
		this.width = this.right-this.left;
		this.height = this.bottom - this.top;

	}
}
export class Place {
	public provider:string;
	public region:string;
	public nodes:string[] = [];
	public location:{longitude:number, latitude:number} = {latitude: 37.50395459919235, longitude: 127.04154662917233}	//default:acornsoft
}


export class Map {
	private container:HTMLElement;
	constructor(el:HTMLElement) {
		this.container = el;
	}

	public render(nodes:any) {

		if(!this.container) return;
		let container:d3.Selection<any, any, any, any> = select(this.container);
		
		// svg
		let svg:d3.Selection<SVGSVGElement, any, SVGElement, any> = container.select<SVGSVGElement>("svg");
		if(svg.size() == 0) svg = container.append("svg");

		//bound 계산, padding 반영
		let bounds:Bounds =  new Bounds(container);

		// svg 크기 지정
		svg.attr("width", bounds.width).attr("height", bounds.height);

		//{provider:"gcp", region:"europe-west2", nodes:[], locatin:{latitude: 37, longitude: 126}}
		const places = nodes.reduce((accumulator, nd) => {
			const provider = nd.provider || "unknown";
			const region = nd.region || "unknown";
			let d = accumulator.find(r => (r.provider==provider && r.region==region) );
			if (!d) {
				d = {provider:provider, region:region, nodes:[], location: REGIONS[provider][region] ? REGIONS[provider][region]["location"]: REGIONS["unknown"]["unknown"]["location"]};
				accumulator.push(d);
			}
			d.nodes.push(nd.name);
			return accumulator
		}, [])

		// rendering
		this.populate(svg, bounds, places);
	}

	private populate(svg:d3.Selection<SVGSVGElement, any, SVGElement, any>,bounds:Bounds, places:Place[]) {

		// projection & geoPath
		const projection = geoMercator()
			.scale(bounds.width / 2.2 / Math.PI)
			.rotate([0, 0])
			.center([0, 0])
			.translate([bounds.width / 2, bounds.height / 1.6]);
		const pathGenerator = geoPath().projection(projection);
  
		// render
		json("https://raw.githubusercontent.com/janasayantan/datageojson/master/world.json").then(
			(data:any) => {
				const g = svg.append("g");
				g.selectAll("path")
				.data(data.features)
				.enter()
				.append("path")
					.attr("class", "country")
					.attr("d", pathGenerator)
					.append("title")
						.text((d:any) => d.properties.name);

			// tip (popup)
			let tip = d3Tip()
				.attr("class", "d3-tip")
				.offset([-5, 0])
				.style("left", "300px")
				.style("top", "400px")
				.html((e:any,d:Place) => {
					return `[${d.provider} ${d.region} - ${d.nodes.length}ea]<br><em>nodes:${d.nodes}</em>`;
				})
				g.call(tip);

			// pin
			g.selectAll(".pin")
				.data(places)
				.enter()
				.append("circle")
				.attr("class", "pin")
				.attr("r", (d:Place)=> d.nodes?d.nodes.length*2:2)
				.attr("transform", (d:Place) => {
					return `translate(${projection([d.location.longitude,d.location.latitude])})`;
				})
				.on("mouseover", tip.show)
				.on("mouseout", tip.hide);

			// zooming
			svg.call(
				zoom().on("zoom", ({ transform }) => {
					g.attr("transform", transform);
				})
			);

		});


	}

}

