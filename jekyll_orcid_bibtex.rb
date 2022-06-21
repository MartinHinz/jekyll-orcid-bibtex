require 'json'
require 'open-uri'

module Jekyll

  class BibliographyFile < StaticFile
    def initialize(site, base, dir, orcid)
      @site = site
      @base = base
      @dir = dir
      @orcid = orcid

      if site.config['author']['orcid']
        url = "https://pub.orcid.org/v2.1/#{orcid}/works"
        response = JSON.load(URI.open(url, 'Accept' => 'application/json'))
      end

      put_codes = response['group'].collect{ |entry| entry['work-summary'] }.flatten.collect{ |entry| entry['put-code'] }

      bibtex_entries = put_codes.map do |put_code|
        work_url = "https://pub.orcid.org/v2.1/#{orcid}/work/#{put_code}";
        response = JSON.load(URI.open(work_url, 'Accept' => 'application/json'));
        response['citation']['citation-value'] if defined? response['citation']['citation-value']
      end .compact!

      File.open(File.expand_path(site.source+"/"+dir+"/"+orcid+".bib"), File::WRONLY|File::CREAT) { |file| file.write(bibtex_entries.join("\n")) }

      super(site, base, dir, orcid)
    end
  end

  class BibliographyGenerator < Generator
    safe true
    priority :highest

    def generate(site)
      if site.config['author']['orcid']
        dir = site.config['scholar'] ? site.config['scholar']['source'] : "./bibliography"
        file = BibliographyFile.new(site, site.source, dir, "#{site.config['author']['orcid']}")
      end
    end
  end

end
