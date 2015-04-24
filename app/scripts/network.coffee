Network = () ->
	width = 700
	height = 500
	circleRadius = 20

	allData = []
	curLinksData = []
	curNodesData = []
	linkedByIndex = {}

	conceptToId = null
	nodesMap = null

	nodesG = null
	linksG = null

	node = null
	link = null

	# initialise witout any concept
	curConcept = null

	force = d3.layout.force()

	network = (selection, data) ->
		allData = setupData(data)

		vis = d3.select(selection).append("svg")
			.attr("width", width)
			.attr("height", height)
		linksG = vis.append("g").attr("id", "links")
		nodesG = vis.append("g").attr("id", "nodes")

		force.size([width, height])

		force.on("tick", forceTick)
			.charge(-1000)
			.linkDistance(100)

		update()

	update = () ->
		curNodesData = filterNodes(allData.nodes)
		curLinksData = filterLinks(allData.links, curNodesData)

		force.nodes(curNodesData)
		updateNodes()

		force.links(curLinksData)
		updateLinks()

		force.start()

		if curConcept
			$('#details').text('')
				.append("<h3>" + curConcept.name + '</h3>')
				.append(curConcept.documents)

	network.toggleFilter = (newFilter) ->
		force.stop()
		setCurConcept(newFilter)
		update()
		
	setupData = (data) ->
		data.nodes.forEach (n) -> 
			n.x = randomnumber=Math.floor(Math.random()*width)
			n.y = randomnumber=Math.floor(Math.random()*height)
			n.radius = circleRadius

		nodesMap = d3.map(data.nodes, (n) -> n.id)
		conceptToId = d3.map(data.nodes, (x) -> x.name)

		data.links.forEach (l) ->
			l.source = nodesMap.get(l.source)
			l.target = nodesMap.get(l.target)

			linkedByIndex["#{l.source.id},#{l.target.id}"] = 1
		data

	neighboring = (a, b) ->
		linkedByIndex[a.id + "," + b.id] or
			linkedByIndex[b.id + "," + a.id]

	filterNodes = (allNodes) ->
		filterdNodes = []

		if curConcept
			filterdNodes.push(curConcept)

			filterdNodes = filterdNodes.concat (allNodes.filter((x) -> neighboring(curConcept, x)))

		filterdNodes


	filterLinks = (allLinks, curNodes) ->
		curNodes = d3.map(curNodes, (x) -> x.id)
		allLinks.filter (l) ->
			curNodes.get(l.source.id) and curNodes.get(l.target.id)

	updateNodes = () ->
		node = nodesG.selectAll("g.xxx")
			.data(curNodesData, (d) -> d.id)
		
		node.enter()
			.append('g')
			.attr('class', 'xxx')
			.call(force.drag)

		node.append("circle")
			.attr("class", "node")
			.attr("r", (d) -> d.radius)
			.style("fill", 'white')
			.style("stroke", '#555')
			.style("stroke-width", 1.0)

		node.append("text")
			.text((x) -> x.name)
			.attr('class', 'label')
			.attr('dy', '-.5em')

		node.append('text')
			.text((x) -> x.documents)
			.attr('class', 'documents')
			.attr('dy', '.5em')

		node.on("mouseover", showDetails)
			.on("mouseout", hideDetails)
			.on("click", navigateNewConcept)

		node.exit().remove()

	updateLinks = () ->
		link = linksG.selectAll("line.link")
			.data(curLinksData, (d) -> "#{d.source.id}_#{d.target.id}")

		link.enter().append("line")
			.attr("class", "link")
			.attr("stroke", "#ddd")
			.attr("stroke-opacity", 0.8)
			.attr("x1", (d) -> d.source.x)
			.attr("y1", (d) -> d.source.y)
			.attr("x2", (d) -> d.target.x)
			.attr("y2", (d) -> d.target.y)

		link.exit().remove()

	# transform to internal filter representation
	setCurConcept = (newConcept) ->
		conceptProccessed = newConcept.split(' ').sort().join()
		curConcept = conceptToId.get conceptProccessed

	forceTick = (e) ->
		node
			.attr("transform", (d, i) -> "translate(" + d.x + "," + d.y + ")")

		link
			.attr("x1", (d) -> d.source.x)
			.attr("y1", (d) -> d.source.y)
			.attr("x2", (d) -> d.target.x)
			.attr("y2", (d) -> d.target.y)

	showDetails = (d, i) ->
		d3.select(this).select('circle')
			.style("stroke-width", 2.0)

	hideDetails = (d, i) ->
		node.select('circle')
			.style("stroke-width", 1.0)

	navigateNewConcept = (d, i) ->
		network.toggleFilter(d.name)

	return network

$ ->
	myNetwork = Network()
	
	d3.json "network.json", (json) ->
		myNetwork("#vis", json)

	$('#searchButton').click ->
		newFilter = $('#searchText').val()
		myNetwork.toggleFilter(newFilter)