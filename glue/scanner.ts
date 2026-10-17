// Thin TypeScript camera scanner helper (under 80 lines).
// Uses html5-qrcode when available in browser or provides scanner callbacks.

export interface ScanResult {
  text: string;
  timestamp: number;
}

export class CameraScanner {
  private scannerInstance: any = null;
  private elementId: string;

  constructor(elementId: string) {
    this.elementId = elementId;
  }

  async start(onSuccess: (decodedText: string) => void, onError?: (err: any) => void): Promise<boolean> {
    try {
      const html5QrCode = (window as any).Html5Qrcode;
      if (!html5QrCode) {
        console.warn('html5-qrcode not loaded on window, using mock scanner fallback');
        return false;
      }
      this.scannerInstance = new html5QrCode(this.elementId);
      const config = { fps: 10, qrbox: { width: 250, height: 250 } };
      await this.scannerInstance.start({ facingMode: 'environment' }, config, onSuccess, onError);
      return true;
    } catch (e) {
      if (onError) onError(e);
      return false;
    }
  }

  async stop(): Promise<void> {
    try {
      if (this.scannerInstance && this.scannerInstance.isScanning) {
        await this.scannerInstance.stop();
        this.scannerInstance.clear();
      }
    } catch (e) {
      console.warn('Error stopping scanner:', e);
    }
  }
}

export function generateScanId(): string {
  return 'scn-' + Math.random().toString(36).substring(2, 9) + '-' + Date.now();
}
