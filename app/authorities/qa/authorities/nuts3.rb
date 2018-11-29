module Qa::Authorities
  class Nuts3 < Qa::Authorities::Base
    # https://ec.europa.eu/eurostat/web/nuts/linked-open-data
    # select ?s ?p ?o  where {graph <http://data.europa.eu/nuts> {?s ?p ?o}}      LIMIT 10
    # subset of irish codes in nuts3

    # possible options converting nuts3 IDs to URIs: 
    # http://irelandsdg.geohive.ie/datasets/OSi::nuts3-generalised-100m-2/geoservice
    # https://tbed.org/eudemo/index.php?tablename=nuts_vw&function=details&where_field=nuts_code&where_value=

    # data from aileen's email, originally https://en.wikipedia.org/wiki/NUTS_3_statistical_regions_of_the_Republic_of_Ireland
    def data
      [
        {
         "Region Code": "IE041",
         "Region Name": "Border Region",
         "Local Government areas included": "Cavan, Donegal, Leitrim, Monaghan, Sligo"
        },
        {
         "Region Code": "IE042",
         "Region Name": "West Region",
         "Local Government areas included": "Mayo, Roscommon, Galway and Galway City"
        },
        {
         "Region Code": "IE051",
         "Region Name": "Mid-West Region",
         "Local Government areas included": "Clare, Tipperary, Limerick City & County"
        },
        {
         "Region Code": "IE052",
         "Region Name": "South-East Region",
         "Local Government areas included": "Carlow, Kilkenny, Wexford, Waterford City & County"
        },
        {
         "Region Code": "IE053",
         "Region Name": "South-West Region",
         "Local Government areas included": "Kerry, Cork and Cork City"
        },
        {
         "Region Code": "IE061",
         "Region Name": "Dublin Region",
         "Local Government areas included": "Dún Laoghaire–Rathdown, Fingal, South Dublin and Dublin City"
        },
        {
         "Region Code": "IE062",
         "Region Name": "Mid-East Region",
         "Local Government areas included": "Kildare, Meath, Wicklow, Louth"
        },
        {
         "Region Code": "IE063",
         "Region Name": "Midlands Region",
         "Local Government areas included": "Laois, Longford, Offaly, Westmeath"
        }
      ]
    end

    def search(_q)
      # case insensitive match
      regex = Regexp.new(Regexp.escape(_q), 'i')
      matching_regions = data.select { |_h| _h[:'Region Name'].match? regex }
      matching_regions.map do |_h|
        {
          id: _h[:'Region Code'],
          label: _h[:'Region Name']
        }
      end
    end

    def show(id)
      data[:'Region Code']
    end
  end
end
