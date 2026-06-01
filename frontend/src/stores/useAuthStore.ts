import { axiosInstance } from "@/lib/axios";
import { create } from "zustand";

interface AuthStore {
	isAdmin: boolean;
	isLoading: boolean;
	error: string | null;
	isAuthenticated: boolean;

	initializeAuth: () => Promise<void>;
	checkAdminStatus: () => Promise<void>;
	logout: () => Promise<void>;
	reset: () => void;
}

export const useAuthStore = create<AuthStore>((set) => ({
	isAdmin: false,
	isLoading: false,
	error: null,
	isAuthenticated: false,

	checkAdminStatus: async () => {
		set({ isLoading: true, error: null });
		try {
			const response = await axiosInstance.get("/admin/check");
			set({ isAdmin: response.data.admin });
		} catch (error: any) {
			set({ isAdmin: false, error: error.response.data.message });
		} finally {
			set({ isLoading: false });
		}
	},

	initializeAuth: async () => {
  set({
    isLoading: true,
    error: null,
  });

  try {
    const response =
      await axiosInstance.get(
        "/admin/check"
      );

    set({
      isAuthenticated: true,
      isAdmin: response.data.admin,
    });
  } catch {
    set({
      isAuthenticated: false,
      isAdmin: false,
    });
  } finally {
    set({
      isLoading: false,
    });
  }
},

	logout: async () => {
    try {
      const response =
        await axiosInstance.post(
          "/auth/logout"
        );

      set({
        isAuthenticated: false,
        isAdmin: false,
      });

      window.location.href =
        response.data.logoutUrl;
    } catch (error) {
      console.error(error);
    }
  },

	reset: () => {
		set({ isAdmin: false, isLoading: false, error: null });
	},
}));
