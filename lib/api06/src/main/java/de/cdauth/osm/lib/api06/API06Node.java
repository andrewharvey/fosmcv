/*
	Copyright © 2010 Candid Dauth

	Permission is hereby granted, free of charge, to any person obtaining
	a copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the Software
	is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
	INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
	PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package de.cdauth.osm.lib.api06;

import org.w3c.dom.Element;

import de.cdauth.osm.lib.APIError;
import de.cdauth.osm.lib.LonLat;
import de.cdauth.osm.lib.Node;
import de.cdauth.osm.lib.VersionedItemCache;
import de.cdauth.osm.lib.Way;

/**
 * Represents a Node in OpenStreetMap.
 */

public class API06Node extends API06GeographicalItem implements Node
{
	/**
	 * Only for serialization.
	 */
	@Deprecated
	public API06Node()
	{
	}

	protected API06Node(Element a_dom, API06API a_api)
	{
		super(a_dom, a_api);
	}

	@Override
	public LonLat getLonLat()
	{
		return new LonLat(Float.parseFloat(getDOM().getAttribute("lon")), Float.parseFloat(getDOM().getAttribute("lat")));
	}

	@Override
	public Way[] getContainingWays() throws APIError
	{
		Way[] ret = (Way[])getAPI().get("/node/"+getID()+"/ways");
		VersionedItemCache<Way> cache = getAPI().getWayFactory().getCache();
		for(Way it : ret)
		{
			((API06Way)it).markAsCurrent();
			cache.cacheObject(it);
		}
		
		// FIXME: Cache this result somehow?
		return ret;
	}
}
