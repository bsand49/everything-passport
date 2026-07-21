import sys
import os
import re

def parse_lcov(file_path, threshold):
    if not os.path.exists(file_path):
        print(f"::error::LCOV file not found: {file_path}")
        sys.exit(1)

    exclude_patterns = [
        r'^test/.*',
        r'.*\.mocks\.dart$',
        r'.*\.g\.dart$',
        r'.*\.freezed\.dart$',
        r'.*/firebase_options.*\.dart$'
    ]

    files_data = []
    current_file = None
    lines_found = 0
    lines_hit = 0
    uncovered_lines = []

    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('SF:'):
                current_file = line[3:]
                lines_found = 0
                lines_hit = 0
                uncovered_lines = []
            elif line.startswith('DA:'):
                parts = line[3:].split(',')
                line_num = int(parts[0])
                hits = int(parts[1])
                lines_found += 1
                if hits > 0:
                    lines_hit += 1
                else:
                    uncovered_lines.append(line_num)
            elif line == 'end_of_record':
                # Check if file should be excluded
                is_excluded = any(re.match(pattern, current_file) for pattern in exclude_patterns)
                if not is_excluded:
                    files_data.append({
                        'file': current_file,
                        'found': lines_found,
                        'hit': lines_hit,
                        'uncovered': uncovered_lines
                    })

    if not files_data:
        print("::error::No coverage data found after filtering.")
        sys.exit(1)

    total_found = sum(f['found'] for f in files_data)
    total_hit = sum(f['hit'] for f in files_data)
    overall_percentage = (total_hit / total_found * 100) if total_found > 0 else 0

    # Generate Markdown Report
    report = ["### Flutter Coverage Report 📊\n"]

    status_icon = "✅" if overall_percentage >= threshold else "❌"
    report.append(f"| Metric | Value |")
    report.append(f"| --- | --- |")
    report.append(f"| Lines Found | {total_found} |")
    report.append(f"| Lines Hit | {total_hit} |")
    report.append(f"| **Coverage** | **{status_icon} {overall_percentage:.2f}%** (Required: {threshold}%) |\n")

    if len(files_data) > 15:
        report.append("<details><summary>Detailed Per-File Report</summary>\n")

    report.append("| File | Coverage | Uncovered Lines |")
    report.append("| :--- | :---: | :--- |")

    for f in sorted(files_data, key=lambda x: x['file']):
        file_perc = (f['hit'] / f['found'] * 100) if f['found'] > 0 else 0
        uncovered_str = ", ".join(map(str, f['uncovered'][:10]))
        if len(f['uncovered']) > 10:
            uncovered_str += "..."
        if not uncovered_str:
            uncovered_str = "-"

        report.append(f"| {f['file']} | {file_perc:.1f}% | {uncovered_str} |")

    if len(files_data) > 15:
        report.append("\n</details>")

    # Write to pr_comment.md
    with open('pr_comment.md', 'w') as f:
        f.write("\n".join(report))

    # Output for Step Summary
    summary_path = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary_path:
        with open(summary_path, 'a') as f:
            f.write("\n".join(report))

    print(f"Coverage: {overall_percentage:.2f}%")
    if overall_percentage < threshold:
        print(f"::error::Code coverage ({overall_percentage:.2f}%) is below the required threshold of {threshold}%")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: parse_lcov.py <lcov_file> <threshold>")
        sys.exit(1)

    lcov_path = sys.argv[1]
    target_threshold = float(sys.argv[2])
    parse_lcov(lcov_path, target_threshold)
