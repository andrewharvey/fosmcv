<%--
	This file is part of the OSM History Viewer.

	OSM History Viewer is free software: you can redistribute it and/or modify
	it under the terms of the GNU Affero General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	OSM History Viewer is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Affero General Public License for more details.

	You should have received a copy of the GNU Affero General Public License
	along with this software. If not, see <http://www.gnu.org/licenses/>.

	Copyright © 2010 Candid Dauth
--%>
<%@page import="java.io.PrintWriter"%>
<%@page import="eu.cdauth.osm.lib.*"%>
<%@page import="eu.cdauth.osm.web.osmhv.*"%>
<%@page import="eu.cdauth.osm.web.osmhv.ChangesetAnalyser.TagChange"%>
<%@page import="static eu.cdauth.osm.web.osmhv.GUI.*"%>
<%@page import="eu.cdauth.osm.web.common.Cache"%>
<%@page import="eu.cdauth.osm.web.common.Queue"%>
<%@page import="java.util.*" %>
<%@page import="java.net.URL" %>
<%@page contentType="text/html; charset=UTF-8" buffer="none" session="false"%>
<%!
	private static final Queue queue = Queue.getInstance();

	private static final int TAG_CHANGES_CHANGED = 0;
	private static final int TAG_CHANGES_CREATED = 1;
	private static final int TAG_CHANGES_DELETED = 2;

	public void jspInit()
	{
		if(ChangesetAnalyser.cache == null)
			ChangesetAnalyser.cache = new Cache<ChangesetAnalyser>(GUI.getCacheDirectory(getServletContext())+"/fosmcv/changeset");
	}
%>
<%
	ID changesetID = null;
	if(request.getParameter("id") != null)
	{
		try {
			changesetID = new ID(request.getParameter("id").replaceFirst("^\\s*#?(.*?)\\s*$", "$1"));
		}
		catch(NumberFormatException e) {
		}
	}

	if(changesetID == null)
	{
		response.setStatus(HttpServletResponse.SC_MOVED_PERMANENTLY);
		URL thisUrl = new URL(request.getRequestURL().toString());
		response.setHeader("Location", new URL(thisUrl.getProtocol(), thisUrl.getHost(), thisUrl.getPort(), request.getContextPath()).toString());
		return;
	}

	GUI gui = new GUI(request, response);
	gui.setTitle(String.format(gui._("Changeset %s"), changesetID.toString()));
	gui.setStyleSheets(new String[]{
		"/javascript/leaflet/leaflet.css"
	});
	gui.setJavaScripts(new String[]{
		"/javascript/leaflet/leaflet.js"
	});

	gui.head();
%>
<%
	response.getWriter().flush();

	Cache.Entry<ChangesetAnalyser> cacheEntry = ChangesetAnalyser.cache.getEntry(changesetID.toString());
	int queuePosition = queue.getPosition(ChangesetAnalyser.worker, changesetID);
	if(cacheEntry == null)
	{
		if(queuePosition == 0)
		{
			Queue.Notification notify = queue.scheduleTask(ChangesetAnalyser.worker, changesetID);
			notify.sleep(20000);
			cacheEntry = ChangesetAnalyser.cache.getEntry(changesetID.toString());
			queuePosition = queue.getPosition(ChangesetAnalyser.worker, changesetID);
		}
	}

	if(cacheEntry != null)
	{
%>

<%
	}

	if(queuePosition > 0)
	{
%>
<p class="scheduled"><strong><%=htmlspecialchars(String.format(gui._("An analysation of this changeset is scheduled. The position in the queue is %d. Reload this page after a while to see the updated version."), queuePosition))%></strong></p>
<%
	}

	if(cacheEntry != null)
	{
		ChangesetAnalyser changes = cacheEntry.content;
		if(changes.exception != null)
		{
%>
<p class="error"><strong><%=htmlspecialchars(changes.exception.toString())%></strong></p>
<%
		}
		else
		{
%>
<h2><%=htmlspecialchars(gui._("Changeset Details"))%></h2>
<dl class="details">
	<dt>ID</dt>
	<dd><%=htmlspecialchars(changesetID.toString())%> <span class="object-links">(<a href="http://api.fosm.org/api/0.6/changeset/<%=htmlspecialchars(changesetID.toString())%>">head</a>)</span> <span class="object-links">(<a href="http://api.fosm.org/api/0.6/changeset/<%=htmlspecialchars(changesetID.toString())%>/download">download</a>)</span></dd>
	<dt><%=htmlspecialchars(gui._("User"))%></dt>
	<dd><a href="http://www.openstreetmap.org/user/<%=htmlspecialchars(urlencode(changes.changeset.getUser().toString()))%>"><%=htmlspecialchars(changes.changeset.getUser().toString())%></a></dd>
	<dt><%=htmlspecialchars(gui._("Creation time"))%></dt>
	<dd><%=htmlspecialchars(changes.changeset.getCreationDate().toString())%></dd>
	<dt><%=htmlspecialchars(gui._("Closing time"))%></dt>
<%
			Date closingDate = changes.changeset.getClosingDate();
			if(closingDate == null)
			{
%>
	<dd><%=htmlspecialchars(gui._("Still open"))%></dd>
<%
			}
			else
			{
%>
	<dd><%=htmlspecialchars(changes.changeset.getClosingDate().toString())%></dd>
<%
			}
%>
</dl>
<dl>
<%
			for(Map.Entry<String,String> tag : changes.changeset.getTags().entrySet())
			{
%>
	<dt><%=htmlspecialchars(tag.getKey())%></dt>
<%
				String format = getTagFormat(tag.getKey());
				String[] values = tag.getValue().split("\\s*;\\s*");
				for(String value : values)
				{
%>
	<dd><%=String.format(format, htmlspecialchars(value))%></dd>
<%
				}
			}
%>
</dl>
<%
			TagChange[] tagChangeObject = null;
			
			for(int tagChangeObjectType = 0; tagChangeObjectType < 3 ; tagChangeObjectType++)
			{
				if(tagChangeObjectType == 0)
				{
%>
<h2><%=htmlspecialchars(gui._("Changed object tags"))%></h2>
<%
				}
				else if(tagChangeObjectType == 1)
				{
%>
<h2><%=htmlspecialchars(gui._("New object tags"))%></h2>
<%
				}
				else if(tagChangeObjectType == 2)
				{
%>
<h2><%=htmlspecialchars(gui._("Deleted object tags"))%></h2>
<%
				}

					switch (tagChangeObjectType) {
						case TAG_CHANGES_CHANGED:
							tagChangeObject = changes.tagChanges;
							break;
						case TAG_CHANGES_CREATED:
							tagChangeObject = changes.tagChangesNewObjects;
							break;
						case TAG_CHANGES_DELETED:
							tagChangeObject = changes.tagChangesDeletedObjects;
							break;
						default: // shouldn't happen
							tagChangeObject = changes.tagChanges;
							break;
					}

				if(tagChangeObject.length == 0)
				{
%>
<p class="nothing-to-do"><%=htmlspecialchars(gui._("No tags have been changed."))%></p>
<%
				}
				else
				{
%>
<ul class="changed-object-tags">
<%
					for(ChangesetAnalyser.TagChange it : tagChangeObject)
					{
						String type,browse;
						if(it.type == Node.class)
						{
							type = gui._("Node");
							browse = "node";
						}
						else if(it.type == Way.class)
						{
							type = gui._("Way");
							browse = "way";
						}
						else if(it.type == Relation.class)
						{
							type = gui._("Relation");
							browse = "relation";
						}
						else
							continue;
%>
	<li><%=htmlspecialchars(type+" "+it.id.toString())%>
	    <span class="object-links">
	        (<a href="http://www.openstreetmap.org/browse/<%=htmlspecialchars(browse + "/" + it.id.toString())%>"><%=htmlspecialchars(gui._("browse"))%></a>) 
	        (<a href="/cgi-bin/fosm-deep-history/<%=htmlspecialchars(browse)%>.php?id=<%=htmlspecialchars(it.id.toString())%>"><%=htmlspecialchars(gui._("deep diff"))%></a>) 
	        (<a href="http://api.fosm.org/api/0.6/<%=htmlspecialchars(browse + "/" + it.id.toString() + "/history")%>"><%=htmlspecialchars(gui._("api history"))%></a>) 
	        (<a href="javascript:gotomap('<%=htmlspecialchars(browse + "/" + it.id.toString())%>')"><%=htmlspecialchars(gui._("gotomap"))%></a>)
	    </span>
		<table>
			<tbody>
<%
						Set<String> tags = new HashSet<String>();

						if ((tagChangeObjectType == TAG_CHANGES_CHANGED) ||
						    (tagChangeObjectType == TAG_CHANGES_DELETED))
							tags.addAll(it.oldTags.keySet());
						if ((tagChangeObjectType == TAG_CHANGES_CHANGED) ||
						    (tagChangeObjectType == TAG_CHANGES_CREATED))
							tags.addAll(it.newTags.keySet());
	
						for(String key : tags)
						{
							String valueOld = null;

							if ((tagChangeObjectType == TAG_CHANGES_CHANGED) ||
							    (tagChangeObjectType == TAG_CHANGES_DELETED))
								valueOld = it.oldTags.get(key);

							String valueNew = null;
						if ((tagChangeObjectType == TAG_CHANGES_CHANGED) ||
						    (tagChangeObjectType == TAG_CHANGES_CREATED))
								valueNew = it.newTags.get(key);
	
							if(valueOld == null)
								valueOld = "";
							if(valueNew == null)
								valueNew = "";
	
							String class1,class2;
							if(valueOld.equals(valueNew))
							{
								class1 = "unchanged";
								class2 = "unchanged";
							}
							else
							{
								class1 = "old";
								class2 = "new";
							}
%>
				<tr>
					<th><%=htmlspecialchars(key)%></th>
					<td class="<%=htmlspecialchars(class1)%>"><%=GUI.formatTag(key, valueOld)%></td>
					<td class="<%=htmlspecialchars(class2)%>"><%=GUI.formatTag(key, valueNew)%></td>
				</tr>
<%
						}
%>
			</tbody>
		</table>
	</li>
<%
					}
%>
</ul>
<%
				}
			}
%>
<h2><%=htmlspecialchars(gui._("Map"))%></h2>
<noscript><p><strong><%=htmlspecialchars(gui._("This map requires JavaScript."))%></strong></p></noscript>
<%
			if(changes.removed.length == 0 && changes.created.length == 0 && changes.unchanged.length == 0)
			{
%>
<p class="nothing-to-do"><%=htmlspecialchars(gui._("No objects were changed in the changeset."))%></p>
<%
			}
			else
			{
%>
<div id="map"></div>
<p class="key">
	<strong>
		Key: 
		<span class="red">before</span> 
		<span class="green">after</span> 
		<span class="blue">unchanged</span>
	</ul>
	</strong>
</p>
<span><a id="map-side-by-side" href="/leaflet-side-by-side.html">Inspect fosm/osm as a side-by-side map.</a></span>
<script type="text/javascript">
// <![CDATA[
	var fosm = new L.TileLayer("/tiles/fosm/mapnik/{z}/{x}/{y}.png",
		{
			attribution: 'Map Data &amp; Map Image &copy; <a href="http://www.openstreetmap.org/">OpenStreetMap</a> &amp; <a href="http://www.fosm.org/">FOSM</a> Contributors <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC BY-SA 2.0</a>',
			maxZoom: 20
		});

	var nearmap = new L.TileLayer("http://www.nearmap.com/maps/?z={z}&x={x}&y={y}&nml=Vert",
		{
			attribution: 'PhotoMaps &copy; <a href="http://www.nearmap.com/">NearMap</a>',
			maxZoom: 24
		});

	var osm = new L.TileLayer("http://tile.openstreetmap.org/{z}/{x}/{y}.png",
		{
			attribution: 'Map Data &amp; Map Image &copy; <a href="http://www.openstreetmap.org/">OpenStreetMap</a> Contributors <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC BY-SA 2.0</a>',
			maxZoom: 18
		});

	// define the layer control
	var layerControl = new L.Control.Layers({
		'FOSM Mapnik': fosm,
		'NearMap PhotoMap (remote)': nearmap,
		'OpenStreetMap.org (remote)': osm
	});

	var map = new L.Map("map", { layers: [fosm] });
	map.addControl(layerControl);

//	window.onresize = function(){ document.getElementById("map").style.height = Math.round(window.innerHeight*.9)+"px"; map.updateSize(); };
//	window.onresize();

	var styleMapUnchanged = {color: "#0000ff", weight: 3, opacity: 0.3};
	var styleMapCreated = {color: "#44ff44", weight: 3, opacity: 0.5};
	var styleMapRemoved = {color: "#ff0000", weight: 3, opacity: 0.5};

	var layerCreated = new L.LayerGroup();
	var layerRemoved = new L.LayerGroup();
	var layerUnchanged = new L.LayerGroup();

	var layerCreatedNodes = new L.LayerGroup();
	var layerRemovedNodes = new L.LayerGroup();
	var layerUnchangedNodes = new L.LayerGroup();

	var addNodeIconClass = L.Icon.extend({
		iconUrl: "/img/markers/33/dark/add.png", 
		iconSize: new L.Point(31,33), 
		iconAnchor: new L.Point(10, 30)
		});
	var modifyNodeIconClass = L.Icon.extend({
		iconUrl: "/img/markers/33/dark/modify.png", 
		iconSize: new L.Point(31,33), 
		iconAnchor: new L.Point(10, 30)
		});
	var removeNodeIconClass = L.Icon.extend({
		iconUrl: "/img/markers/33/dark/remove.png", 
		iconSize: new L.Point(31,33), 
		iconAnchor: new L.Point(10, 30)
		});
	var addNodeIcon = new addNodeIconClass();
	var modifyNodeIcon = new modifyNodeIconClass();
	var removeNodeIcon = new removeNodeIconClass();
	

<%
				for(Segment segment : changes.removed)
				{
%>
	layerRemoved.addLayer(
		new L.Polyline(
			[
				new L.LatLng(<%=segment.getNode1().getLonLat().getLat()%>, <%=segment.getNode1().getLonLat().getLon()%>),
				new L.LatLng(<%=segment.getNode2().getLonLat().getLat()%>, <%=segment.getNode2().getLonLat().getLon()%>)
			], styleMapRemoved
		)
	);
<%
				}

				for(Segment segment : changes.created)
				{
%>
	layerCreated.addLayer(
		new L.Polyline(
			[
				new L.LatLng(<%=segment.getNode1().getLonLat().getLat()%>, <%=segment.getNode1().getLonLat().getLon()%>),
				new L.LatLng(<%=segment.getNode2().getLonLat().getLat()%>, <%=segment.getNode2().getLonLat().getLon()%>)
			], styleMapCreated
		)
	);
<%
				}

				for(Segment segment : changes.unchanged)
				{
%>
	layerUnchanged.addLayer(
		new L.Polyline(
			[
				new L.LatLng(<%=segment.getNode1().getLonLat().getLat()%>, <%=segment.getNode1().getLonLat().getLon()%>),
				new L.LatLng(<%=segment.getNode2().getLonLat().getLat()%>, <%=segment.getNode2().getLonLat().getLon()%>)
			], styleMapUnchanged
		)
	);
<%
				}
%>

<%
				for(Node node : changes.removedNodes)
				{
%>
	layerRemovedNodes.addLayer(
		new L.Marker(
			new L.LatLng(<%=node.getLonLat().getLat()%>, <%=node.getLonLat().getLon()%>),
			{icon: removeNodeIcon}
		).bindPopup('Node ID: <%=node.getID()%><br><a href="/cgi-bin/fosm-deep-history/node.php?id=<%=node.getID()%>">deep diff</a>')
	);
<%
				}

				for(Node node : changes.createdNodes)
				{
%>
	layerCreatedNodes.addLayer(
		new L.Marker(
			new L.LatLng(<%=node.getLonLat().getLat()%>, <%=node.getLonLat().getLon()%>),
			{icon: addNodeIcon}
		).bindPopup('Node ID: <%=node.getID()%><br><a href="/cgi-bin/fosm-deep-history/node.php?id=<%=node.getID()%>">deep diff</a>')
	);
<%
				}

				for(Node node : changes.unchangedNodes)
				{
%>
	layerUnchangedNodes.addLayer(
		new L.Marker(
			new L.LatLng(<%=node.getLonLat().getLat()%>, <%=node.getLonLat().getLon()%>),
			{icon: modifyNodeIcon}
		).bindPopup('Node ID: <%=node.getID()%><br><a href="/cgi-bin/fosm-deep-history/node.php?id=<%=node.getID()%>">deep diff</a>')
	);
<%
				}
%>

	map.addLayer(layerUnchanged);
	map.addLayer(layerRemoved);
	map.addLayer(layerCreated);

	map.addLayer(layerUnchangedNodes);
	map.addLayer(layerRemovedNodes);
	map.addLayer(layerCreatedNodes);

	//map.fitBounds(extent);
	map.fitWorld();

// ]]>
</script>
<%
			}
		}
%>
<p class="create-date"><%=String.format(htmlspecialchars(gui._("This page is current as of %s.")), gui.formatDate(cacheEntry == null ? null : cacheEntry.date))%></p>
<%
	}

	gui.foot();
%>
