import {
  PLVLiveSceneSDK,
  PLVMemberChannelViewer,
  PLVMemberErrorEvent,
  PLVToastUtils
} from '@polyvharmony/live-scenes-sdk';
import { lateInit, lazy, MutableObserver } from '@polyvharmony/media-player-sdk';
import { PLVSAMemberListDataSource } from './item/PLVSAMemberListDataSource';
import { PLVSAMemberListItem } from './item/PLVSAMemberListItem';
import { display } from '@kit.ArkUI';
import { PLVSAPageDataBus } from '../../common/PLVSAPageDataBus';

@CustomDialog
export struct PLVSAMemberLayout {
  controller: CustomDialogController = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus

  aboutToAppear(): void {
    this.pageDataBus.memberLayoutVisible.setValue(true)
  }

  build() {
    if (this.isPortrait()) {
      PLVSAMemberLayoutPort()
    } else {
      PLVSAMemberLayoutLand()
    }
  }

  aboutToDisappear(): void {
    this.pageDataBus.memberLayoutVisible.setValue(false)
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }
}

@Component
struct PLVSAMemberLayoutPort {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly dataSource = lazy(() => new PLVSAMemberListDataSource(this.sdk.memberManager.channelViewers))
  @State private channelViewerCount: number = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.memberManager.channelViewerCount.observe(it => this.channelViewerCount = it)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Text($r('app.string.plvsa_member_online_count', this.channelViewerCount.toString()))
        .fontSize(18)
        .fontColor('#F0F1F5')
      List() {
        LazyForEach(
          this.dataSource.value,
          (channelViewer: PLVMemberChannelViewer) => {
            PLVSAMemberListItem({
              viewer: channelViewer
            })
          },
          (channelViewer: PLVMemberChannelViewer) => channelViewer.viewerId
        )
      }
      .width('100%')
      .height(300)
      .margin({
        top: 16
      })
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 32,
      right: 32,
      top: 32
    })
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
    .backgroundColor('#2C2C2C')
  }

  aboutToDisappear(): void {
    this.dataSource.value.destroy()
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVSAMemberLayoutLand {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly dataSource = lazy(() => new PLVSAMemberListDataSource(this.sdk.memberManager.channelViewers))
  @State private channelViewerCount: number = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.memberManager.channelViewerCount.observe(it => this.channelViewerCount = it)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Text($r('app.string.plvsa_member_online_count', this.channelViewerCount.toString()))
        .fontSize(18)
        .fontColor('#F0F1F5')

      List() {
        LazyForEach(
          this.dataSource.value,
          (channelViewer: PLVMemberChannelViewer) => {
            PLVSAMemberListItem({
              viewer: channelViewer
            })
          },
          (channelViewer: PLVMemberChannelViewer) => channelViewer.viewerId
        )
      }
      .width('100%')
      .layoutWeight(1)
      .margin({
        top: 16
      })
    }
    .width(400)
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 32,
      right: 32,
      top: 32
    })
    .borderRadius({
      topLeft: 16,
      bottomLeft: 16
    })
    .backgroundColor('#2C2C2C')
  }

  aboutToDisappear(): void {
    this.dataSource.value.destroy()
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}
