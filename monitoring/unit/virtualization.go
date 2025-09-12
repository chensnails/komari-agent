package monitoring

import (
	"os"
	"os/exec"
	"runtime"
	"strings"

	cpuid "github.com/klauspost/cpuid/v2"
)

func Virtualized() string {
	// Windows: use CPUID to detect hypervisor presence and vendor.
	if runtime.GOOS == "windows" {
		return detectByCPUID()
	}

	// Linux/others: prefer systemd-detect-virt if available; fallback to CPUID.
	if out, err := exec.Command("systemd-detect-virt").Output(); err == nil {
		virt := strings.TrimSpace(string(out))
		if virt != "" {
			return virt
		}
	}

	// Non-systemd environments (e.g., Alpine containers): try container heuristics.
	if ct := detectContainer(); ct != "" {
		return ct
	}

	// Fallback (any OS): CPUID hypervisor bit and vendor mapping.
	return detectByCPUID()
}

// detectByCPUID uses cpuid to check if running under a hypervisor and maps vendor to a common name.
func detectByCPUID() string {
	if !cpuid.CPU.VM() {
		// Align with systemd-detect-virt for bare metal.
		return "none"
	}
	vendor := strings.ToLower(cpuid.CPU.HypervisorVendorString)

	vendorMap := map[string][]string{
		"kvm":       {"kvm"},
		"microsoft": {"microsoft", "hyper-v", "msvm", "mshyperv"},
		"vmware":    {"vmware"},
		"xen":       {"xen"},
		"bhyve":     {"bhyve"},
		"qemu":      {"qemu"},
		"parallels": {"parallels"},
		"oracle":    {"oracle", "virtualbox", "vbox"},
		"acrn":      {"acrn"},
	}

	for name, keys := range vendorMap {
		for _, key := range keys {
			if vendor == key || strings.Contains(vendor, key) {
				return name
			}
		}
	}
	if vendor != "" {
		return vendor
	}
	return "virtualized"
}

// detectContainer returns empty string for OpenWrt system
// since we don't need container detection
func detectContainer() string {
	return ""
}

func fileExists(p string) bool {
	if st, err := os.Stat(p); err == nil && !st.IsDir() {
		return true
	}
	return false
}

// parseCgroupForContainer is not used in OpenWrt system
func parseCgroupForContainer() string {
	return "" 
}
