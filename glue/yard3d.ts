// Thin TypeScript 3D parking yard visualizer (strictly under 80 lines).
// Renders asphalt ground, bays with zone colors, 3D box cars, and walking line from gate.

export class Yard3DVisualizer {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D | null;

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
  }

  public render(slots: any[], selectedSlotCode: string): void {
    if (!this.ctx) return;
    const ctx = this.ctx, w = this.canvas.width, h = this.canvas.height;
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = '#080F1D';
    ctx.fillRect(0, 0, w, h);

    const gateX = w / 2, gateY = h - 25;
    ctx.fillStyle = '#FFC21A';
    ctx.fillRect(gateX - 25, gateY, 50, 5);
    ctx.font = '10px monospace';
    ctx.fillText('TERMINAL GATE', gateX - 35, gateY + 16);

    let selX = 0, selY = 0;
    const cols = 8, slotW = 34, slotH = 46, startX = 40, startY = 30;

    slots.slice(0, 24).forEach((slot, i) => {
      const col = i % cols, row = Math.floor(i / cols);
      const x = startX + col * (slotW + 10), y = startY + row * (slotH + 16);
      const isSel = slot.code === selectedSlotCode, isOcc = slot.state === 'occupied';

      ctx.fillStyle = isSel ? 'rgba(255, 194, 26, 0.25)' : isOcc ? 'rgba(239, 68, 68, 0.15)' : 'rgba(16, 185, 129, 0.1)';
      ctx.strokeStyle = isSel ? '#FFC21A' : isOcc ? '#EF4444' : '#10B981';
      ctx.lineWidth = isSel ? 2 : 1;
      ctx.strokeRect(x, y, slotW, slotH);
      ctx.fillRect(x, y, slotW, slotH);

      if (isOcc) {
        ctx.fillStyle = '#334155';
        ctx.fillRect(x + 4, y + 6, slotW - 8, slotH - 12);
        ctx.fillStyle = '#64748B';
        ctx.fillRect(x + 6, y + 10, slotW - 12, slotH - 22);
      }
      if (isSel) {
        selX = x + slotW / 2; selY = y + slotH / 2;
        ctx.strokeStyle = '#FFC21A';
        ctx.strokeRect(x - 2, y - 2, slotW + 4, slotH + 4);
      }
    });

    if (selX > 0 && selY > 0) {
      ctx.strokeStyle = '#FFC21A';
      ctx.setLineDash([4, 4]);
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(gateX, gateY);
      ctx.lineTo(gateX, selY + 25);
      ctx.lineTo(selX, selY + 25);
      ctx.lineTo(selX, selY);
      ctx.stroke();
      ctx.setLineDash([]);
    }
  }
}
