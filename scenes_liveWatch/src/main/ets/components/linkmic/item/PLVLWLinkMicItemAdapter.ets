import { PLVLinkMicViewer } from '@polyvharmony/live-scenes-sdk';
import { lateInit } from '@polyvharmony/media-player-sdk';
import { PLVLWLinkMicListItemPpt } from './PLVLWLinkMicListItemPpt';
import { PLVLWLinkMicListItemViewer } from './PLVLWLinkMicListItemViewer';
import { PLVLWLinkMicMainItemPpt } from './PLVLWLinkMicMainItemPpt';
import { PLVLWLinkMicMainItemViewer } from './PLVLWLinkMicMainItemViewer';

@Component
export struct PLVLWLinkMicItemAdapter {
  pos: 'main' | 'list' = lateInit()
  item: PLVLWLinkmicItem | undefined = lateInit()

  build() {
    Stack() {
      if (this.pos === 'main' && this.item?.type === 'viewer') {
        PLVLWLinkMicMainItemViewer({
          linkmicItem: this.item,
          viewer: this.item.viewer
        })
      }
      if (this.pos === 'main' && this.item?.type === 'ppt') {
        PLVLWLinkMicMainItemPpt()
      }
      if (this.pos === 'list' && this.item?.type === 'viewer') {
        PLVLWLinkMicListItemViewer({
          linkmicItem: this.item,
          viewer: this.item.viewer
        })
      }
      if (this.pos === 'list' && this.item?.type === 'ppt') {
        PLVLWLinkMicListItemPpt()
      }
    }
  }
}

export class PLVLWLinkmicItem {
  type?: 'viewer' | 'ppt'
  viewer?: PLVLinkMicViewer

  get id(): string {
    if (this.type === 'ppt') {
      return 'ppt'
    }
    if (this.viewer) {
      return this.viewer.xcomponentId
    }
    return '0'
  }
}