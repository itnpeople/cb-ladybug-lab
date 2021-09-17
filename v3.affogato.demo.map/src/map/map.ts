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
	private outlineEl:d3.Selection<SVGGElement, any, SVGElement, any>;
	private projection:d3.GeoProjection;
	private tip:any;

	constructor(el:HTMLElement) {

		if(!el) return;
		let container:d3.Selection<any, any, any, any> = select(el);
		
		// svg
		let svg:d3.Selection<SVGSVGElement, any, SVGElement, any> = container.select<SVGSVGElement>("svg");
		if(svg.size() == 0) svg = container.append("svg");

		//bound 계산, padding 반영
		let bounds:Bounds =  new Bounds(container);

		// svg 크기 지정
		svg.attr("width", bounds.width).attr("height", bounds.height);

		//outline g
		this.outlineEl = svg.select<SVGGElement>("g.outline");
		if(this.outlineEl.size() > 0) this.outlineEl.remove();
		this.outlineEl = svg.append("g").attr("class","outline");


		//tip
		if (!this.tip) {
			this.tip = d3Tip()
				.attr("class", "tip")
				.offset([-5, 0])
				.style("left", "300px")
				.style("top", "400px")
				.html((e:any,d:Place) => {
					return `[${d.provider} ${d.region} - ${d.nodes.length}ea]<br><em>nodes:${d.nodes}</em>`;
				})
				this.outlineEl.call(this.tip);
		}

		//tip
		let tip = d3Tip()
			.attr("class", "tip")
			.offset([-5, 0])
			.style("left", "300px")
			.style("top", "400px")
			.html((e:any,d:Place) => {
				return `[${d.provider} ${d.region} - ${d.nodes.length}ea]<br><em>nodes:${d.nodes}</em>`;
			})
			this.outlineEl.call(tip);


		// projection & geoPath
		this.projection = geoMercator()
			.scale(bounds.width / 2.2 / Math.PI)
			.rotate([0, 0])
			.center([0, 0])
			.translate([bounds.width / 2, bounds.height / 1.6]);
		const pathGenerator = geoPath().projection(this.projection);


		// render
		json("https://raw.githubusercontent.com/janasayantan/datageojson/master/world.json").then(
			(data:any) => {
				this.outlineEl.selectAll("path")
				.data(data.features)
				.enter()
				.append("path")
					.attr("class", "country")
					.attr("d", pathGenerator)
					.append("title")
						.text((d:any) => d.properties.name);

				// zooming
				svg.call(
					zoom().on("zoom", ({ transform }) => {
						this.outlineEl.attr("transform", transform);
					})
				);
		});

	}

	public render(data:any) {

		//{provider:"gcp", region:"europe-west2", nodes:[], locatin:{latitude: 37, longitude: 126}}
		const places = data.reduce((accumulator, nd) => {
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


		// pin
		this.outlineEl.selectAll(".pin")
			.remove()
			.data(places)
			.enter()
			.append("circle")
			.attr("class", "pin")
			.attr("r", (d:Place)=> d.nodes?d.nodes.length*6:6)
			.attr("transform", (d:Place) => {
				return `translate(${this.projection([d.location.longitude,d.location.latitude])})`;
			})
			.on("mouseover", this.tip.show)
			.on("mouseout", this.tip.hide);


	}


}

