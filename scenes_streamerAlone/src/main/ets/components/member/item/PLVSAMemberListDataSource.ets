import { PLVMemberChannelViewer } from '@polyvharmony/live-scenes-sdk';
import { extendArray, MutableObserver, State } from '@polyvharmony/media-player-sdk';

export class PLVSAMemberListDataSource implements IDataSource {
  private readonly listeners: DataChangeListener[] = []
  private readonly stateChannelViewers: State<PLVMemberChannelViewer[]>
  private list: PLVMemberChannelViewer[] = []
  private observers: MutableObserver[] = []

  constructor(stateChannelViewers: State<PLVMemberChannelViewer[]>) {
    this.stateChannelViewers = stateChannelViewers
    stateChannelViewers.observe(viewers => {
      this.list = viewers
      this.listeners.forEach(listener => listener.onDataReloaded())
    }).pushTo(this.observers)
  }

  totalCount(): number {
    return this.list.length
  }

  getData(index: number): PLVMemberChannelViewer {
    return this.list[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    extendArray(this.listeners).remove_ext(listener)
  }

  destroy() {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}