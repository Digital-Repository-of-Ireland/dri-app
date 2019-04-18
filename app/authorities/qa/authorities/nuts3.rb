module Qa::Authorities
  class Nuts3 < Qa::Authorities::Base
    def search(_q)
      # case insensitive match
      regex = Regexp.new(Regexp.escape(_q), 'i')

      matching_regions = all.select do |sub_hash|
        sub_hash['Region Name'].match? regex
      end

      matching_regions.map do |region|
        {
          id:    region['Region Code'],
          label: region['Region Name']
        }
      end
    end

    def show(id)
      all.select { |sub_hash| sub_hash['Region Code'] == id }
    end

    # possible options converting nuts3 IDs to URIs:
    # https://ec.europa.eu/eurostat/web/nuts/background
    # https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:02003R1059-20180118&from=EN
    # http://irelandsdg.geohive.ie/datasets/OSi::nuts3-generalised-100m-2/geoservice
    # https://tbed.org/eudemo/index.php?tablename=nuts_vw&function=details&where_field=nuts_code&where_value=
    def all
      Psych.safe_load(File.open(nuts_path))
    end

    private

      def nuts_path
        Rails.root.join('app', 'authorities', 'qa', 'data', 'nuts3_ie.yml')
      end
  end
end
