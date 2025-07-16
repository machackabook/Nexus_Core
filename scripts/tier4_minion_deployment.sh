#!/bin/bash

# TIER 4: MINION DEPLOYMENT SYSTEM
# Audio Checkpoint Integration

echo "=== NEXUS MINION NETWORK INITIALIZATION ==="
say "Initializing Minion Network - Tier 4"

source "/Users/nexus/NEXUS_CORE/scripts/audio_alerts.sh"

# 4.1 Web Crawler Framework
echo "[4.1] Deploying web crawler framework..."
MINION_BASE="/Volumes/Transfer/NEXUS_AUTOMATOR/minions"
mkdir -p "$MINION_BASE"/{crawlers,bots,evolution,logs}

# Create GoogleBot-type crawler
cat > "$MINION_BASE/crawlers/nexus_crawler.py" << 'EOF'
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
EOF

chmod +x "$MINION_BASE/crawlers/nexus_crawler.py"

# 4.2 Script Evolution Engine
echo "[4.2] Creating script evolution engine..."
cat > "$MINION_BASE/evolution/evolution_engine.py" << 'EOF'
#!/usr/bin/env python3
"""
NEXUS Evolution Engine - Self-improving script system
Analyzes script performance and suggests optimizations
"""

import os
import json
import time
import subprocess
import hashlib
from pathlib import Path

class EvolutionEngine:
    def __init__(self):
        self.base_path = Path("/Volumes/Transfer/NEXUS_AUTOMATOR/minions")
        self.evolution_log = self.base_path / "logs" / "evolution.log"
        self.performance_db = self.base_path / "evolution" / "performance.json"
        
    def analyze_script_performance(self, script_path):
        """Analyze script execution performance"""
        start_time = time.time()
        
        try:
            result = subprocess.run(['bash', script_path], 
                                  capture_output=True, 
                                  text=True, 
                                  timeout=300)
            
            execution_time = time.time() - start_time
            
            performance_data = {
                'script': script_path,
                'execution_time': execution_time,
                'exit_code': result.returncode,
                'timestamp': time.time(),
                'success': result.returncode == 0,
                'output_length': len(result.stdout),
                'error_length': len(result.stderr)
            }
            
            self.log_performance(performance_data)
            return performance_data
            
        except subprocess.TimeoutExpired:
            self.audio_alert("Script timeout - potential optimization needed", "warning")
            return None
    
    def suggest_optimizations(self, script_path):
        """Analyze script and suggest optimizations"""
        with open(script_path, 'r') as f:
            content = f.read()
        
        suggestions = []
        
        # Basic optimization checks
        if 'sleep' in content and 'while true' in content:
            suggestions.append("Consider reducing sleep intervals in infinite loops")
        
        if content.count('subprocess.run') > 5:
            suggestions.append("Multiple subprocess calls detected - consider batching")
        
        if 'find /' in content:
            suggestions.append("Full filesystem search detected - consider limiting scope")
        
        return suggestions
    
    def evolve_script(self, script_path):
        """Create evolved version of script with optimizations"""
        suggestions = self.suggest_optimizations(script_path)
        
        if suggestions:
            evolved_path = script_path.replace('.sh', '_evolved.sh')
            
            # Create evolved version (basic example)
            with open(script_path, 'r') as f:
                content = f.read()
            
            # Apply basic optimizations
            evolved_content = content.replace('sleep 10', 'sleep 5')  # Reduce sleep time
            evolved_content = evolved_content.replace('find /', 'find /Users')  # Limit scope
            
            with open(evolved_path, 'w') as f:
                f.write(evolved_content)
            
            os.chmod(evolved_path, 0o755)
            
            self.audio_alert(f"Script evolved: {evolved_path}", "success")
            return evolved_path
        
        return None
    
    def log_performance(self, data):
        """Log performance data"""
        with open(self.evolution_log, 'a') as f:
            f.write(f"{time.ctime()}: {json.dumps(data)}\n")
    
    def audio_alert(self, message, alert_type="info"):
        """Send audio alert"""
        subprocess.run(['say', f"{alert_type}: {message}"], check=False)

if __name__ == "__main__":
    engine = EvolutionEngine()
    
    # Scan for scripts to analyze
    script_dir = Path("/Users/nexus/NEXUS_CORE/scripts")
    for script in script_dir.glob("*.sh"):
        print(f"Analyzing: {script}")
        engine.analyze_script_performance(str(script))
        engine.evolve_script(str(script))
EOF

chmod +x "$MINION_BASE/evolution/evolution_engine.py"

# 4.3 Minion Control Center
echo "[4.3] Creating minion control center..."
cat > "$MINION_BASE/minion_control.sh" << 'EOF'
#!/bin/bash

# NEXUS Minion Control Center
source "/Users/nexus/NEXUS_CORE/scripts/audio_alerts.sh"

MINION_BASE="/Volumes/Transfer/NEXUS_AUTOMATOR/minions"

deploy_crawler() {
    local target_url="$1"
    audio_checkpoint "info" "Deploying crawler to $target_url"
    
    python3 "$MINION_BASE/crawlers/nexus_crawler.py" "$target_url" &
    echo $! > "$MINION_BASE/logs/crawler_pid.txt"
}

start_evolution_engine() {
    audio_checkpoint "info" "Starting evolution engine"
    
    python3 "$MINION_BASE/evolution/evolution_engine.py" &
    echo $! > "$MINION_BASE/logs/evolution_pid.txt"
}

monitor_minions() {
    while true; do
        # Check crawler status
        if [ -f "$MINION_BASE/logs/crawler_pid.txt" ]; then
            crawler_pid=$(cat "$MINION_BASE/logs/crawler_pid.txt")
            if ! ps -p "$crawler_pid" > /dev/null 2>&1; then
                audio_checkpoint "warning" "Crawler process terminated"
            fi
        fi
        
        # Check evolution engine status
        if [ -f "$MINION_BASE/logs/evolution_pid.txt" ]; then
            evolution_pid=$(cat "$MINION_BASE/logs/evolution_pid.txt")
            if ! ps -p "$evolution_pid" > /dev/null 2>&1; then
                audio_checkpoint "warning" "Evolution engine terminated"
            fi
        fi
        
        sleep 60
    done
}

case "$1" in
    "deploy")
        deploy_crawler "$2"
        ;;
    "evolve")
        start_evolution_engine
        ;;
    "monitor")
        monitor_minions
        ;;
    *)
        echo "Usage: $0 {deploy|evolve|monitor} [url]"
        ;;
esac
EOF

chmod +x "$MINION_BASE/minion_control.sh"

audio_checkpoint "success" "Minion Network Initialization Complete"
echo "✓ Minion Network Deployment Complete"
say "Minion Network Deployed - Proceeding to Tier 5"
