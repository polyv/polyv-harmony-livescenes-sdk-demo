import { PLVLiveSceneSDK, PLVToastUtils } from "@polyvharmony/live-scenes-sdk"
import { lateInit } from "@polyvharmony/media-player-sdk"

@Component
export struct PLVSAMoreCloseRoomButton {
  iconPadding: number = 8
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private isCloseRoom: boolean = false

  aboutToAppear(): void {
    this.isCloseRoom = this.sdk.chatroomManager.isCloseRoom
    this.sdk.chatroomManager.eventNotify.on('close_room', this.onCloseRoomEvent)
  }

  build() {
    Column() {
      Image($r('app.media.plvsa_more_close_room_icon'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text(this.isCloseRoom ? $r('app.string.plvsa_chat_cancel_close_room_text') : $r('app.string.plvsa_chat_close_room_text'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      this.sdk.chatroomManager.switchCloseRoom()
    })
  }

  private readonly onCloseRoomEvent = (isCloseRoom: boolean) => {
    this.isCloseRoom = isCloseRoom
    PLVToastUtils.shortShow(isCloseRoom ? $r('app.string.plvsa_chat_close_room_toast') : $r('app.string.plvsa_chat_cancel_close_room_toast'))
  }

  aboutToDisappear(): void {
    this.sdk.chatroomManager.eventNotify.off('close_room', this.onCloseRoomEvent)
  }

}