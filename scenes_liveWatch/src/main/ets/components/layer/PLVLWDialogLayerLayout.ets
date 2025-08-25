import { PLVLiveSceneSDK } from "@polyvharmony/live-scenes-sdk"
import { lateInit } from "@polyvharmony/media-player-sdk"
import { PLVLWCommonDef } from "../../common/PLVLWCommonDef"
import { clearAllDialog, PLVLWGlobalStateDialog } from "../../common/PLVLWGlobalStateDialog"

@Component
export struct PLVLWDialogLayerLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()

  aboutToDisappear(): void {
    clearAllDialog(this.sdk.uniqueId)
  }

  build() {
    Stack() {
      PLVLWGlobalStateDialog({ dialogName: 'desc', backPriority: PLVLWCommonDef.BACK_PRIORITY_GLOBAL_DIALOG_DESC_TAB })
      PLVLWGlobalStateDialog({ dialogName: 'previous', backPriority: PLVLWCommonDef.BACK_PRIORITY_GLOBAL_DIALOG_PREVIOUS })
    }
    .hitTestBehavior(HitTestMode.None)
  }
}