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
