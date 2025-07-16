#!/usr/bin/env python3
"""
NEXUS Web Crawler - GoogleBot-type autonomous crawler
Designed for systematic information gathering and evolution
"""

import requests
import time
import json
import os
import subprocess
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup
import logging

class NexusCrawler:
    def __init__(self, base_url, max_depth=3):
        self.base_url = base_url
        self.max_depth = max_depth
        self.visited_urls = set()
        self.crawl_data = []
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'NEXUS-Crawler/1.0 (Autonomous Information Gathering System)'
        })
        
        # Setup logging
        logging.basicConfig(
            filename='/Volumes/Transfer/NEXUS_AUTOMATOR/minions/logs/crawler.log',
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
    
    def audio_alert(self, message, alert_type="info"):
        """Send audio alert through system"""
        subprocess.run(['say', f"{alert_type}: {message}"], check=False)
    
    def crawl_page(self, url, depth=0):
        """Crawl a single page and extract information"""
        if depth > self.max_depth or url in self.visited_urls:
            return
        
        try:
            self.visited_urls.add(url)
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract page data
            page_data = {
                'url': url,
                'title': soup.title.string if soup.title else 'No Title',
                'depth': depth,
                'timestamp': time.time(),
                'links': [],
                'content_summary': self.extract_content_summary(soup)
            }
            
            # Extract links for further crawling
            for link in soup.find_all('a', href=True):
                full_url = urljoin(url, link['href'])
                if self.is_valid_url(full_url):
                    page_data['links'].append(full_url)
            
            self.crawl_data.append(page_data)
            self.logger.info(f"Crawled: {url} (depth: {depth})")
            
            # Recursive crawling
            for link in page_data['links'][:5]:  # Limit to 5 links per page
                time.sleep(1)  # Be respectful
                self.crawl_page(link, depth + 1)
                
        except Exception as e:
            self.logger.error(f"Error crawling {url}: {str(e)}")
            self.audio_alert(f"Crawler error on {url}", "warning")
    
    def extract_content_summary(self, soup):
        """Extract meaningful content summary"""
        # Remove script and style elements
        for script in soup(["script", "style"]):
            script.decompose()
        
        text = soup.get_text()
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        text = ' '.join(chunk for chunk in chunks if chunk)
        
        return text[:500]  # First 500 characters
    
    def is_valid_url(self, url):
        """Check if URL is valid for crawling"""
        parsed = urlparse(url)
        return parsed.scheme in ['http', 'https'] and parsed.netloc
    
    def save_results(self):
        """Save crawling results"""
        output_file = f"/Volumes/Transfer/NEXUS_AUTOMATOR/minions/logs/crawl_results_{int(time.time())}.json"
        with open(output_file, 'w') as f:
            json.dump(self.crawl_data, f, indent=2)
        
        self.audio_alert(f"Crawl complete - {len(self.crawl_data)} pages processed", "success")
        return output_file

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        crawler = NexusCrawler(sys.argv[1])
        crawler.crawl_page(sys.argv[1])
        crawler.save_results()
    else:
        print("Usage: python3 nexus_crawler.py <start_url>")
