/**
 * Client-side camera QR scanner and token validation bridge for ParkRide gate barriers.
 */

export interface ScanResult {
  rawToken: string;
  isValidStructure: boolean;
  payload?: {
    bookingId: string;
    vehicleNumber: string;
    terminalId: string;
    slotId: string;
    exp: number;
  };
  signature?: string;
  error?: string;
}

export interface ScannerConfig {
  videoElementId: string;
  onScanSuccess: (result: ScanResult) => void;
  onScanError?: (err: Error) => void;
  preferredFacingMode?: 'environment' | 'user';
}

export class QRScannerBridge {
  private videoElement: HTMLVideoElement | null = null;
  private stream: MediaStream | null = null;
  private isScanning: boolean = false;
  private scanIntervalId: number | null = null;

  constructor(private config: ScannerConfig) {}

  /**
   * Requests camera permissions and attaches stream to video element.
   */
  public async start(): Promise<boolean> {
    if (typeof navigator === 'undefined' || !navigator.mediaDevices) {
      this.handleError(new Error('MediaDevices API not supported in this browser environment.'));
      return false;
    }

    try {
      this.videoElement = document.getElementById(this.config.videoElementId) as HTMLVideoElement;
      if (!this.videoElement) {
        throw new Error(`Video element #${this.config.videoElementId} not found.`);
      }

      this.stream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: this.config.preferredFacingMode || 'environment',
          width: { ideal: 1280 },
          height: { ideal: 720 }
        },
        audio: false
      });

      this.videoElement.srcObject = this.stream;
      await this.videoElement.play();
      this.isScanning = true;
      this.startFrameLoop();
      return true;
    } catch (err) {
      this.handleError(err instanceof Error ? err : new Error(String(err)));
      return false;
    }
  }

  /**
   * Decodes and validates ParkRide HMAC token string format.
   */
  public parseToken(tokenStr: string): ScanResult {
    const parts = tokenStr.trim().split('.');
    if (parts.length !== 2) {
      return {
        rawToken: tokenStr,
        isValidStructure: false,
        error: 'Malformed token structure. Expected <payload>.<signature>'
      };
    }

    try {
      // Decode Base64 URL-safe payload
      const base64 = parts[0].replace(/-/g, '+').replace(/_/g, '/');
      const jsonStr = decodeURIComponent(
        atob(base64)
          .split('')
          .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
          .join('')
      );
      const parsed = JSON.parse(jsonStr);

      return {
        rawToken: tokenStr,
        isValidStructure: true,
        payload: {
          bookingId: parsed.booking_id,
          vehicleNumber: parsed.vehicle_number,
          terminalId: parsed.terminal_id,
          slotId: parsed.slot_id,
          exp: parsed.exp
        },
        signature: parts[1]
      };
    } catch (e) {
      return {
        rawToken: tokenStr,
        isValidStructure: false,
        error: `Payload parsing failed: ${e instanceof Error ? e.message : String(e)}`
      };
    }
  }

  /**
   * Frame extraction loop for BarcodeDetector or Canvas inspection.
   */
  private startFrameLoop(): void {
    const checkFrame = async () => {
      if (!this.isScanning || !this.videoElement) return;

      // Check for BarcodeDetector API if available in browser
      if ('BarcodeDetector' in window) {
        try {
          const barcodeDetector = new (window as any).BarcodeDetector({
            formats: ['qr_code']
          });
          const barcodes = await barcodeDetector.detect(this.videoElement);
          if (barcodes.length > 0) {
            const result = this.parseToken(barcodes[0].rawValue);
            this.config.onScanSuccess(result);
          }
        } catch (_) {
          // Fallback or frame skip
        }
      }

      if (this.isScanning) {
        this.scanIntervalId = window.setTimeout(checkFrame, 200);
      }
    };

    this.scanIntervalId = window.setTimeout(checkFrame, 200);
  }

  private handleError(err: Error): void {
    if (this.config.onScanError) {
      this.config.onScanError(err);
    } else {
      console.error('[QRScannerBridge Error]', err);
    }
  }

  /**
   * Stops camera stream and cleans up media tracks.
   */
  public stop(): void {
    this.isScanning = false;
    if (this.scanIntervalId !== null) {
      clearTimeout(this.scanIntervalId);
      this.scanIntervalId = null;
    }
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }
    if (this.videoElement) {
      this.videoElement.srcObject = null;
    }
  }
}
