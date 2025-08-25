import { PLVCommonConstants, PLVLiveSceneSDK, PLVTextUtils } from '@polyvharmony/live-scenes-sdk'
import { isLiteralTrue, lateInit, MutableObserver, PLVMediaPlayerAppContext } from '@polyvharmony/media-player-sdk'
import { LengthUnit } from '@kit.ArkUI'
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus'

@Component
export struct PLVLWPinnedAnnouncementLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private announcement: string | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.layoutDataBus.preload.bulletinEvent.observe(event => {
      if (event && isLiteralTrue(event.isTop)) {
        this.announcement = this.html2Text(event.content ?? '')
      } else {
        this.announcement = undefined
      }
    })
      .pushTo(this.observers)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      RelativeContainer() {
        Text() {
          ContainerSpan() {
            Span('  ')
              .fontSize(10)
            ImageSpan($r('app.media.plvlw_chatroom_pinned_announcement_span_icon'))
              .width(12)
              .height(12)
              .verticalAlign(ImageSpanAlignment.CENTER)
            Span($r('app.string.plvlw_chat_pinned_announcement_span_text'))
              .fontSize(10)
              .fontColor($r('app.color.plvlw_pinned_announcement_span_text'))
              .baselineOffset({
                value: 1,
                unit: LengthUnit.VP
              })
            Span('  ')
              .fontSize(10)
          }
          .textBackgroundStyle({
            color: $r('app.color.plvlw_pinned_announcement_span_background'),
            radius: '20vp'
          })

          Span(' ').fontSize(12)

          Span(this.announcement)
            .fontSize(14)
            .fontColor($r('app.color.plvlw_pinned_announcement_text'))
        }
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .ellipsisMode(EllipsisMode.END)
        .alignRules({
          center: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Center },
          start: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
          end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .margin({
          right: 16
        })

        Image($r('app.media.plvlw_chatroom_pinned_announcement_close_icon'))
          .width(16)
          .height(16)
          .alignRules({
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
            end: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .margin({
            bottom: 2
          })
          .onClick(() => {
            this.announcement = undefined
          })
      }
      .width(303)
      .height(46)
      .borderRadius(12)
      .padding({
        left: 8,
        right: 8,
        top: 3,
        bottom: 3
      })
      .backgroundColor($r('app.color.plvlw_chat_content_item_background'))
    }
    .padding({
      bottom: 4
    })
    .onClick(() => {
      this.sdk.interactManager.showBulletin()
    })
    .visibility(this.announcement ? Visibility.Visible : Visibility.None)
  }

  private html2Text(src: string): string {
    let result = src
    // 替换所有的 \n 为 ' '
    result = result.replace(/\n/g, ' ');
    // 替换所有的 <img>
    result = result.replace(/<img[^>]*>/g, PLVMediaPlayerAppContext.getString($r('app.string.plvlw_chat_pinned_announcement_image_alt')));
    // 替换所有的 <*>
    result = result.replace(/<[^>]*>/g, '');
    result = PLVTextUtils.convertSpecialString(result)!;
    return result;
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}