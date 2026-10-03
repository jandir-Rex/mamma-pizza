// src/pages/UserProfiles.tsx
import PageBreadcrumb from "@/components/common/PageBreadCrumb";
import PageMeta from "@/components/common/PageMeta";
import DangerZone from "@/components/UserProfile/DangerZone";
import Security from "@/components/UserProfile/Security";
import UserAddressCard from "@/components/UserProfile/UserAddressCard";
import UserMetaCard from "@/components/UserProfile/UserMetaCard";

export default function UserProfiles() {
  return (
    <>
      <PageMeta
        title="Mi Perfil | Mamma Pizza"
        description="Gestión de cuenta personal y seguridad en Mamma Pizza"
      />
      <PageBreadcrumb pageTitle="Mi Perfil" />
      <div className="space-y-6">
        <UserMetaCard />
        <UserAddressCard />
        <Security />
        <DangerZone />
      </div>
    </>
  );
}