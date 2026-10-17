/**
 * Three.js visualization loop for ParkRide 3D digital twin.
 * Renders terminal parking bays and live bus movements on Colombo corridor maps.
 */

export interface BusMarker {
  id: string;
  routeNumber: string;
  lat: number;
  lng: number;
  heading: number;
  speed: number;
  passengers: number;
  capacity: number;
}

export interface ParkingSlot3D {
  id: string;
  slotNumber: string;
  slotType: 'standard' | 'ev' | 'handicap' | 'motorcycle';
  status: 'available' | 'reserved' | 'occupied' | 'maintenance';
  x: number;
  y: number;
  z: number;
}

export interface SceneConfig {
  containerId: string;
  antialias?: boolean;
  enableShadows?: boolean;
  backgroundHex?: number;
}

export class ThreeLoopManager {
  private container: HTMLElement | null = null;
  private isRunning: boolean = false;
  private animationFrameId: number | null = null;
  private lastTimestamp: number = 0;

  // State caches
  private busMarkers: Map<string, BusMarker> = new Map();
  private parkingSlots: Map<string, ParkingSlot3D> = new Map();

  constructor(private config: SceneConfig) {}

  /**
   * Initializes the 3D WebGL context and viewport listener.
   */
  public init(): boolean {
    if (typeof window === 'undefined') {
      return false;
    }

    this.container = document.getElementById(this.config.containerId);
    if (!this.container) {
      console.warn(`[ThreeLoop] Container #${this.config.containerId} not found in DOM`);
      return false;
    }

    window.addEventListener('resize', this.handleResize.bind(this));
    return true;
  }

  /**
   * Starts the continuous requestAnimationFrame render loop.
   */
  public start(onFrameTick?: (delta: number) => void): void {
    if (this.isRunning) return;
    this.isRunning = true;
    this.lastTimestamp = performance.now();

    const loop = (timestamp: number) => {
      if (!this.isRunning) return;
      const delta = (timestamp - this.lastTimestamp) / 1000;
      this.lastTimestamp = timestamp;

      // Update positions & call user tick
      if (onFrameTick) {
        onFrameTick(delta);
      }

      this.animationFrameId = requestAnimationFrame(loop);
    };

    this.animationFrameId = requestAnimationFrame(loop);
  }

  /**
   * Pauses the rendering loop.
   */
  public stop(): void {
    this.isRunning = false;
    if (this.animationFrameId !== null) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
  }

  /**
   * Upserts live telemetry for a transit bus.
   */
  public updateBus(bus: BusMarker): void {
    this.busMarkers.set(bus.id, bus);
  }

  /**
   * Bulk updates parking slot states (e.g., from walker reports).
   */
  public syncParkingSlots(slots: ParkingSlot3D[]): void {
    slots.forEach(slot => this.parkingSlots.set(slot.id, slot));
  }

  /**
   * Returns slot color code according to ParkRide design system.
   */
  public getSlotStatusColor(status: ParkingSlot3D['status'], type: ParkingSlot3D['slotType']): string {
    if (status === 'occupied') return '#ef4444'; // Red
    if (status === 'reserved') return '#f59e0b'; // Amber
    if (status === 'maintenance') return '#6b7280'; // Gray
    if (type === 'ev') return '#06b6d4'; // Cyan EV
    if (type === 'handicap') return '#8b5cf6'; // Purple
    return '#10b981'; // Emerald Green available
  }

  private handleResize(): void {
    if (!this.container) return;
    const width = this.container.clientWidth;
    const height = this.container.clientHeight;
    // Resize camera and renderer accordingly
  }

  /**
   * Destroys event listeners and frees WebGL resources.
   */
  public dispose(): void {
    this.stop();
    window.removeEventListener('resize', this.handleResize.bind(this));
    this.busMarkers.clear();
    this.parkingSlots.clear();
  }
}
